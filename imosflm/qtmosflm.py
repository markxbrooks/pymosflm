"""
Loading CBF, TIFF and H5 files in the style of Mosflm
Mark Brooks (c) 2025 Princeton, U.S.A.
"""

import argparse
import os
import sys
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path

import h5py
from PySide6.QtWidgets import QApplication, QMainWindow, QFileDialog, QVBoxLayout, QHBoxLayout, QLabel, QSlider, QPushButton, QTextEdit, QWidget, QComboBox
from PySide6.QtGui import QImage, QPixmap, QPalette, QColor, QPainter, QPen
from PySide6.QtCore import Qt, QSize, QPoint

from PIL import Image, ImageTk, ImageOps, ImageEnhance
import fabio  # Import FabIO
import matplotlib.pyplot as plt
import cv2
import numpy as np
# from image_grouping import *

# Set environment variables
os.environ["QT_LOGGING_RULES"] = "*.debug=false"
os.environ['MAINTAINER'] = 'mosflm@mrc-lmb.cam.ac.uk'
os.environ['MOSFLM_VERSION_REQUIRED'] = '7.4'
os.environ['TKIMAGELOAD'] = '0'
os.environ['EXPERTDETECTORSETTINGS'] = '0'
os.environ['SPIRAL'] = '0'
os.environ['HDF5file'] = '0'

# Debugging setup
debugging = os.getenv('MOSFLM_DEBUG', '0') == '1'

# CCP4i2 mode setup
ccp4i2 = os.getenv('CCP4I2', '0') == '1'
if ccp4i2:
    logging.debug("ccp4i2 mode: ON")

# Fastload mode setup
fastload = os.getenv('FASTLOAD', '0') == '1'
if fastload:
    logging.debug("fastload mode: ON")


def compute_theta_and_resolution(pixel_x, pixel_y, metadata):
    """
    Compute the scattering angle (theta) and resolution at a given pixel.

    Parameters:
        pixel_x (float): X-coordinate of the pixel
        pixel_y (float): Y-coordinate of the pixel
        metadata (dict): Dictionary containing extracted instrument parameters

    Returns:
        theta (float): Scattering angle in degrees
        resolution (float): Resolution in Ångstroms
    """
    # Extract required parameters
    beam_center_x = metadata["beam_centre_x"]  # Beam center X (in pixels)
    beam_center_y = metadata["beam_centre_y"]  # Beam center Y (in pixels)
    detector_distance = metadata["detector_distance"][0]  # Distance in mm
    wavelength = metadata["incident_wavelength"]  # X-ray wavelength in Å
    pixel_size = metadata["x_pixel_size"]  # Pixel size in mm

    # Convert pixel coordinates to mm distances from beam center
    delta_x = (pixel_x - beam_center_x) * pixel_size
    delta_y = (pixel_y - beam_center_y) * pixel_size

    # Compute R (distance from beam center to the pixel in mm)
    R = np.sqrt(delta_x ** 2 + delta_y ** 2)

    # Compute theta in radians
    theta_rad = np.arctan(R / detector_distance)

    # Convert theta to degrees
    theta_deg = np.degrees(theta_rad)

    # Compute resolution using Bragg's Law
    resolution = wavelength / (2 * np.sin(theta_rad))

    return theta_deg, resolution


import h5py
import numpy as np

def extract_nx_class_and_omega(hdf5_path):
    """Extract and print NX_class and omega attributes from an HDF5 file, searching all levels."""
    try:
        with h5py.File(hdf5_path, "r") as f:
            logging.info("\n--- Checking for NX_class and Omega ---")

            def search_attributes(group, path=""):
                for name, item in group.items():
                    full_path = f"{path}/{name}" if path else name

                    # Ensure the item has attributes before accessing
                    if isinstance(item, (h5py.Group, h5py.Dataset)) and hasattr(item, "attrs"):
                        for attr, value in item.attrs.items():
                            if attr == "NX_class":
                                logging.info(f"NX_class found in {full_path}: {value}")

                            if attr == "axes":
                                # Ensure value is properly handled (array vs. scalar)
                                if isinstance(value, (bytes, str)):
                                    if b"omega" in value.encode() if isinstance(value, str) else value:
                                        logging.info(f"Omega axis found in {full_path}: {value}")
                                elif isinstance(value, (list, tuple, np.ndarray)):
                                    if any(b"omega" in str(v).encode() if isinstance(v, str) else v for v in value):
                                        logging.info(f"Omega axis found in {full_path}: {value}")

                    # Recursively search deeper levels
                    if isinstance(item, h5py.Group):
                        search_attributes(item, full_path)

            # Start recursive search from root
            search_attributes(f)

            # Checking specific metadata for important sections
            metadata_paths = [
                "/entry/data",
                "/entry/instrument/detector",
                "/entry/instrument"
            ]

            for meta_path in metadata_paths:
                if meta_path in f:
                    logging.info(f"\n--- Checking {meta_path} Attributes ---")
                    for attr, value in f[meta_path].attrs.items():
                        logging.info(f"{attr}: {value}")

    except Exception as ex:
        logging.info(f"Error: {ex} occurred")


class IMosflmApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.beam_x = None
        self.beam_y = None
        self.detector_distance = 200
        self.incident_wavelength = None
        self.x_pixel_size = 0.075
        self.y_pixel_size = 0.075
        self.setWindowTitle("iMosflm")
        self.setGeometry(100, 100, 800, 1000)
        self.current_image = None
        self.current_file = None
        self.dataset = None
        self.num_frames = 0
        self.slice_size = 10  # Number of frames to load at once
        self.beam_center = None

        # Main widget and layout
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)

        # Resolution display
        resolution_layout = QHBoxLayout()
        self.resolution_label = QLabel("Resolution: N/A")
        resolution_layout.addWidget(self.resolution_label)

        self.x_pixel_label = QLabel("x pixel: N/A")
        resolution_layout.addWidget(self.x_pixel_label)

        self.y_pixel_label = QLabel("y pixel: N/A")
        resolution_layout.addWidget(self.y_pixel_label)

        self.theta_label= QLabel(f"theta: N/A radians")
        resolution_layout.addWidget(self.theta_label)

        layout.addLayout(resolution_layout)

        # Dataset selection
        dataset_layout = QHBoxLayout()
        dataset_label = QLabel("Dataset")
        dataset_layout.addWidget(dataset_label)
        
        self.dataset_combo = QComboBox()
        self.dataset_combo.currentIndexChanged.connect(self.change_dataset)
        dataset_layout.addWidget(self.dataset_combo)
        layout.addLayout(dataset_layout)

        # Image display
        self.image_label = QLabel("No image loaded")
        self.image_label.setMinimumHeight(700)  # Set minimum height for the image label
        self.image_label.setMouseTracking(True)
        self.image_label.mouseMoveEvent = self.mouse_move_event
        layout.addWidget(self.image_label)

        # Frame slider and label
        frame_layout = QHBoxLayout()
        self.frame_slider = QSlider(Qt.Horizontal)
        self.frame_slider.setFixedHeight(20)  # Set fixed height for the slider
        self.frame_slider.valueChanged.connect(self.update_frame)
        frame_layout.addWidget(self.frame_slider)

        self.frame_label = QLabel("Frame: 0")
        frame_layout.addWidget(self.frame_label)
        layout.addLayout(frame_layout)

        # Buttons
        button_layout = QHBoxLayout()
        layout.addLayout(button_layout)

        open_button = QPushButton("Open")
        open_button.clicked.connect(self.open_file)
        button_layout.addWidget(open_button)

        invert_button = QPushButton("Invert")
        invert_button.clicked.connect(self.invert_image)
        button_layout.addWidget(invert_button)

        histogram_button = QPushButton("Histogram")
        histogram_button.clicked.connect(self.show_histogram)
        button_layout.addWidget(histogram_button)

        # Contrast slider and label
        contrast_layout = QHBoxLayout()
        self.contrast_slider = QSlider(Qt.Horizontal)
        self.contrast_slider.setFixedHeight(20)  # Set fixed height for the slider
        self.contrast_slider.setRange(50, 300)
        self.contrast_slider.setValue(100)
        self.contrast_slider.valueChanged.connect(self.update_contrast)
        contrast_layout.addWidget(self.contrast_slider)

        self.contrast_label = QLabel("Contrast: 100")
        contrast_layout.addWidget(self.contrast_label)
        layout.addLayout(contrast_layout)

    def open_file(self):
        """
        ooen_file

        :return: None
        """
        file_path, _ = QFileDialog.getOpenFileName(self, "Open Image", "", "Image Files (*.jpg *.png *.gif *.tif *.tiff *.cbf *.h5)")
        if file_path:
            self.current_file = file_path
            logging.info(f"file_path: {file_path}")
            if file_path.lower().endswith('.cbf'):
                self.display_cbf_image(file_path)
            elif file_path.lower().endswith('.h5'):
                # extract_nx_class_and_omega(file_path)
                self.extract_instrument_metadata(file_path)
                self.load_hdf5_image(file_path)
            else:
                self.display_image(file_path)

    def display_image(self, file_path):
        """ display_image """
        logging.info(f"display_image: {file_path}")
        try:
            image = Image.open(file_path)
            self.current_image = image
            self.show_image(image)
        except Exception as e:
            logging.error(f"Error displaying image: {e}")
            logging.debug(f"Failed to load image: {e}")

    def traverse_hdf5(self, group, path):
        """Recursively print attributes and datasets in an HDF5 group."""
        # Print attributes of the current group
        if group.attrs:
            logging.info(f"\nAttributes in {path}:")
            for attr, value in group.attrs.items():
                logging.info(f"  {attr}: {value}")

        # Iterate through datasets and subgroups
        for name, item in group.items():
            full_path = f"{path}/{name}"

            if isinstance(item, h5py.Group):  # If it's a subgroup, recurse
                logging.info(f"\n--- Entering {full_path} ---")
                self.traverse_hdf5(item, full_path)

            elif isinstance(item, h5py.Dataset):  # If it's a dataset, print its value
                try:
                    value = item[()]  # Extract dataset value

                    if full_path == r"/entry/instrument/detector/beam_centre_x":
                        self.beam_x = value
                    elif full_path == r"/entry/instrument/detector/beam_centre_y":
                        self.beam_y = value
                    elif full_path == r"/entry/instrument/detector/detector_distance":
                        self.detector_distance = value
                    elif full_path == r"/entry/instrument/beam/incident_wavelength":
                        self.incident_wavelength = value
                    elif full_path == r"/entry/instrument/detector/x_pixel_size":
                        self.x_pixel_size = value
                    elif full_path == r"/entry/instrument/detector/y_pixel_size":
                        self.y_pixel_size = value
                    logging.info(f"{full_path}: {value}")

                except Exception as e:
                    logging.info(f"Could not read {full_path}: {e}")

    def extract_instrument_metadata(self, hdf5_path):
        """Recursively extract and print all metadata from /entry/instrument in an HDF5 file."""
        try:
            with h5py.File(hdf5_path, "r") as f:
                instrument_path = "/entry/instrument"

                if instrument_path in f:
                    logging.info(f"\n--- Extracting Metadata from {instrument_path} ---")
                    self.traverse_hdf5(f[instrument_path], instrument_path)
                else:
                    logging.info(f"Path '{instrument_path}' not found in the HDF5 file.")

        except Exception as ex:
            logging.info(f"Error: {ex} occurred")

    def display_cbf_image(self, file_path):
        """ display_cbf_image """
        try:
            cbf_image = fabio.open(file_path)
            data = cbf_image.data
            image = Image.fromarray(data)
            self.current_image = image.convert("L")
            self.show_image(self.current_image)
        except Exception as e:
            logging.error(f"Failed to load CBF image: {e}")

    def load_hdf5_image(self, image_path):
        """Load and display an HDF5 image stack with metadata extraction."""
        try:
            with h5py.File(image_path, "r") as f:
                dataset_path = "/entry/data"
                if dataset_path not in f:
                    raise ValueError(f"Dataset '{dataset_path}' not found in {image_path}")

                group = f[dataset_path]
                datasets = [name for name in group.keys() if isinstance(group[name], h5py.Dataset)]
                if not datasets:
                    raise ValueError("No datasets found under '/entry/data'")

                # Extract beam center
                detector_path = "/entry/instrument/detector"
                if detector_path in f:
                    detector_group = f[detector_path]
                    print("Detector attributes:", list(detector_group.attrs.keys()))  # Debugging line

                    # Print all attributes for debugging
                    for attr, value in detector_group.attrs.items():
                        print(f"{attr}: {value}")

                    # Attempt to get beam center
                    # beam_centre_x = detector_group.attrs.get("beam_centre_x", None)
                    # beam_centre_y = detector_group.attrs.get("beam_centre_y", None)

                    beam_centre_x = self.beam_x
                    beam_centre_y = self.beam_y

                    #if beam_centre_x is None or beam_centre_y is None:
                    #    raise ValueError("Beam center coordinates not found.")
                else:
                    raise ValueError(f"Detector path '{detector_path}' not found.")
                if beam_centre_x is None or beam_centre_y is None:
                    raise ValueError("Beam center coordinates not found.")
                    return
                self.beam_center = (beam_centre_x, beam_centre_y)

                # Populate the combo box with dataset names
                self.dataset_combo.clear()
                self.dataset_combo.addItems(datasets)

                # Select the first dataset
                self.dataset = group[datasets[0]]
                self.num_frames = self.dataset.shape[0]

                # Configure slider range
                self.frame_slider.setMinimum(0)
                self.frame_slider.setMaximum(self.num_frames - 1)

                # Load the first frame
                self.display_hdf5_image(0)
        except Exception as ex:
            print(f"Error: {ex} occurred")

    def change_dataset(self, index):
        """Change the dataset based on the combo box selection."""
        dataset_name = self.dataset_combo.itemText(index)
        with h5py.File(self.current_file, "r") as f:
            dataset_path = f"/entry/data/{dataset_name}"
            self.dataset = f[dataset_path]
            self.num_frames = self.dataset.shape[0]
            self.frame_slider.setMaximum(self.num_frames - 1)
            self.display_hdf5_image(0)

    def update_frame(self, start_index):
        """ update_frame """
        if self.dataset is not None:
            self.display_hdf5_image(start_index)
            self.frame_label.setText(f"Frame: {start_index}")

    def display_hdf5_image(self, start_index):
        """Display a slice of frames from the HDF5 dataset with improved contrast and no white borders."""
        try:
            if self.dataset is None:
                raise ValueError("No dataset loaded.")

            # Select the slice of frames
            end_index = min(start_index + self.slice_size, self.num_frames)
            frame_data = self.dataset[start_index:end_index, :, :]

            # Compute mean and standard deviation
            # mean_val = np.mean(frame_data)
            # std_val = np.std(frame_data)

            # Define 5σ clipping bounds
            # lower_bound = mean_val - 5 * std_val
            # upper_bound = mean_val + 5 * std_val

            # Clip data within 5σ range
            # frame_clipped = np.clip(frame_data, lower_bound, upper_bound)

            # Normalize with percentile-based contrast enhancement
            # p_low, p_high = np.percentile(frame_clipped, (2, 98))  # Adjust percentiles as needed
            # frame_clipped = np.clip(frame_clipped, p_low, p_high)
            # frame_stretched = (frame_clipped - p_low) / (p_high - p_low)  # Contrast stretch
            # frame_normalized = (frame_stretched * 255).astype(np.uint8)

            # Convert frames to NumPy array if not already
            frame_data = np.array(frame_data)

            # Convert to grayscale if needed
            if frame_data.ndim == 3:  # Ensure it's a grayscale image
                gray = frame_data
            else:
                gray = cv2.cvtColor(frame_data, cv2.COLOR_RGB2GRAY)

            # Create a mask for non-white areas (assume white is near 255)
            mask = gray < 240  # Pixels below 240 are considered part of the image

            # Compute mean and standard deviation only for non-white areas
            valid_pixels = frame_data[mask]
            mean_val = np.mean(valid_pixels)
            std_val = np.std(valid_pixels)

            # Exclude values outside 5 standard deviations
            lower_bound = mean_val - 5 * std_val
            upper_bound = mean_val + 5 * std_val
            frame_filtered = np.clip(frame_data, lower_bound, upper_bound)

            # Normalize the filtered data
            p_low, p_high = np.percentile(frame_filtered[mask], (2, 98))  # Adjust percentiles as needed
            frame_clipped = np.clip(frame_filtered, p_low, p_high)
            frame_stretched = (frame_clipped - p_low) / (p_high - p_low)
            frame_normalized = (frame_stretched * 255).astype(np.uint8)

            # Apply Adaptive Histogram Equalization (CLAHE)
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))  # Adjust clipLimit
            enhanced_frames = [clahe.apply(frame) for frame in frame_normalized]

            # Apply Gamma Correction
            gamma = 1.2  # Adjust this value as needed
            gamma_corrected = [np.power(frame / 255.0, gamma) * 255 for frame in enhanced_frames]
            gamma_corrected = [frame.astype(np.uint8) for frame in gamma_corrected]

            # Create a PIL image from the average of the processed slice
            self.current_image = Image.fromarray(np.mean(gamma_corrected, axis=0).astype(np.uint8))
            self.show_image(self.current_image)
            logging.info(f"Frames {start_index} to {end_index} displayed successfully.")
        except Exception as ex:
            logging.error(f"Error: {ex} occurred")

    def show_image_without_rings(self, image):
        """ show_image """
        logging.info(f"show_image: {image}")
        try:
            image = image.convert("RGB")
            width, height = image.size
            data = image.tobytes("raw", "RGB")
            qimage = QImage(data, width, height, 3 * width, QImage.Format_RGB888)
            pixmap = QPixmap.fromImage(qimage)
            self.image_label.setPixmap(pixmap.scaled(self.image_label.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation))
        except Exception as ex:
            logging.error(f"Error: {ex} occurred")

    def show_image(self, image):
        """Display the image with resolution rings."""
        try:
            logging.info(f"show_image received image: mode={image.mode}, size={image.size}")

            # Ensure the image is in 'RGB' mode for display
            if image.mode != "RGB":
                image = image.convert("RGB")

            width, height = image.size
            data = image.tobytes("raw", "RGB")  # Ensure raw RGB format
            qimage = QImage(data, width, height, 3 * width, QImage.Format_RGB888)
            pixmap = QPixmap.fromImage(qimage)

            # Draw resolution rings
            painter = QPainter(pixmap)
            pen = QPen(QColor(255, 0, 0), 2)  # Red color, 2 pixels wide
            painter.setPen(pen)

            # Use beam center for resolution rings
            center = QPoint(int(self.beam_center[0]), int(self.beam_center[1]))
            radii = [50, 100, 150, 200]  # Example radii, adjust as needed
            for radius in radii:
                painter.drawEllipse(center, radius, radius)

            painter.end()

            self.image_label.setPixmap(pixmap.scaled(self.image_label.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation))

        except Exception as ex:
            logging.error(f"Error in show_image: {ex}")


    def invert_image(self):
        """ invert_image """
        logging.info(f"invert_image")
        if self.current_image:
            try:
                inverted_image = ImageOps.invert(self.current_image.convert("RGB"))
                self.current_image = inverted_image
                self.show_image(inverted_image)
            except Exception as ex:
                logging.error(f"Error: {ex} occurred")

    def update_contrast(self, value):
        """ update_contrast """
        logging.info(f"update_contrast: {value}")
        if self.current_image:
            contrast_factor = value / 100.0
            enhancer = ImageEnhance.Contrast(self.current_image)
            adjusted_image = enhancer.enhance(contrast_factor)
            self.current_image = adjusted_image
            self.show_image(adjusted_image)
            self.contrast_label.setText(f"Contrast: {value}")

    def show_histogram(self):
        """ show_histogram """
        logging.info("show_histogram")
        if self.current_image:
            grayscale_image = self.current_image.convert("L")
            image_array = np.array(grayscale_image) / 255.0
            histogram, bin_edges = np.histogram(image_array, bins=256, range=(0.0, 1.0))

            plt.figure("Histogram")
            plt.title("Grayscale Histogram")
            plt.xlabel("Grayscale value")
            plt.ylabel("Pixel count")
            plt.xlim([0.0, 1.0])
            plt.plot(bin_edges[0:-1], histogram)
            plt.show()

    def resizeEvent(self, event):
        """ resizeEvent """
        logging.info("resizeEvent")
        try:
            if self.current_image:
                self.show_image(self.current_image)
            super().resizeEvent(event)
        except Exception as ex:
            logging.error(f"Error: {ex} occurred")

    def mouse_move_event(self, event):
        if self.current_image and self.beam_center:
            x = event.position().x()
            y = event.position().y()
            metadata = {
                "beam_centre_x": self.beam_center[0],
                "beam_centre_y": self.beam_center[1],
                "detector_distance": self.detector_distance,
                "incident_wavelength": self.incident_wavelength,
                "x_pixel_size": self.x_pixel_size,
                "y_pixel_size": self.y_pixel_size
            }
            theta, resolution = compute_theta_and_resolution(x, y, metadata)
            self.x_pixel_label.setText(f"x pixel: {x:.0f}")
            self.y_pixel_label.setText(f"y pixel: {y:.0f}")
            self.theta_label.setText(f"theta: {theta:.0f} radians")
            self.resolution_label.setText(f"Resolution: {resolution:.2f} Å")
            logging.info(f"mouse_move_event received metadata: {metadata}")


def parse_arguments():
    """ parse_arguments """
    logging.info("parse_arguments")     
    parser = argparse.ArgumentParser(description='iMosflm Application')
    parser.add_argument('--ccp4i2', action='store_true', help='Autosaves an iMosflm session file upon exit')
    parser.add_argument('--debug', '-d', action='store_true', help='Creates a large output file for debugging purposes')
    parser.add_argument('--expert', '-e', action='store_true', help='Permits access to advanced detector settings')
    parser.add_argument('--fastload', '-f', action='store_true', help='Attempt to speed loading of many images offline')
    parser.add_argument('--version', '-v', action='store_true', help='Displays the program version and required Mosflm version, then exits')
    # Remove the explicit --help argument
    return parser.parse_args()


def setup_logging():
    """Set up logging configuration"""
    try:
        # Create logs directory in user's home directory
        log_dir = Path.home() / ".qtmosflm" / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)

        # Log file path
        log_file = log_dir / "qtmosflm.log"
        logging.debug(f"Setting up logging to: {log_file}")

        # Reset root handlers
        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)

        # Configure rotating file logging
        file_handler = RotatingFileHandler(
            str(log_file),
            maxBytes=1024 * 1024,  # 1MB per file
            backupCount=5,  # Keep 5 backup files
            encoding="utf-8",
        )
        file_handler.setLevel(logging.DEBUG)
        file_formatter = logging.Formatter(
            "%(filename)-14s| %(lineno)-5s| %(levelname)-8s| %(message)-24s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        file_handler.setFormatter(file_formatter)

        # Configure console logging
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_formatter = logging.Formatter(
            "%(filename)-14s| %(lineno)-5s| %(levelname)-8s| %(message)-24s"
        )
        console_handler.setFormatter(console_formatter)

        # Configure root logger
        logging.root.setLevel(logging.DEBUG)
        logging.root.addHandler(file_handler)
        logging.root.addHandler(console_handler)

        logging.info("Logging setup complete")
        logging.info("QtMosflm starting up...")
        logging.debug(f"Log file: {log_file}")
        return log_file

    except Exception as ex:
        logging.debug(f"Error setting up logging: {str(ex)}")
        raise


def main():
    """ main entry point"""
    setup_logging()
    args = parse_arguments()

    # Set environment variables based on arguments
    if args.ccp4i2:
        os.environ['CCP4I2'] = '1'
        logging.debug("* CCP4i2 mode on - be VERY sure you want this")

    if args.debug:
        os.environ['MOSFLM_DEBUG'] = '1'
        logging.debug("* full debugging turned on")

    if args.expert:
        os.environ['EXPERTDETECTORSETTINGS'] = '1'
        logging.debug("* Expert mode on - be VERY sure you want this")

    if args.fastload:
        os.environ['FASTLOAD'] = '1'
        logging.debug("* FASTLOAD mode on")

    if args.version:
        logging.debug(f"* {os.environ.get('IMOSFLM_VERSION', 'Unknown version')}")
        sys.exit()

    # Initialize and run the application
    app = QApplication(sys.argv)
    window = IMosflmApp()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
