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
from PySide6.QtWidgets import QApplication, QMainWindow, QFileDialog, QVBoxLayout, QHBoxLayout, QLabel, QSlider, QPushButton, QTextEdit, QWidget, QComboBox, QCheckBox
from PySide6.QtGui import QImage, QPixmap, QPalette, QColor, QPainter, QPen
from PySide6.QtCore import Qt, QSize, QPoint

from PIL import Image, ImageTk, ImageOps, ImageEnhance
import fabio  # Import FabIO
import matplotlib.pyplot as plt
import cv2
import numpy as np
from contourpy.chunk import two_factors
from pefile import two_way_dict

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


def compute_two_theta_and_resolution(pixel_x, pixel_y, metadata):
    """
    Compute the scattering angle (theta) and resolution at a given pixel.

    Parameters:
        pixel_x (float): X-coordinate of the pixel.
        pixel_y (float): Y-coordinate of the pixel.
        metadata (dict): Dictionary containing extracted instrument parameters.

    Returns:
        tuple: (theta (float), resolution (float))
            - theta: Scattering angle in degrees.
            - resolution: Resolution in Ångstroms.

    Raises:
        ValueError: If any required metadata key is missing or if detector_distance is zero.
    """
    logging.info("----------------------------------------")
    logging.info(f"Computing theta and resolution for pixel \tx: {pixel_x:.0f}, y: {pixel_y:.0f}")

    required_keys = ["beam_centre_x", "beam_centre_y", "detector_distance",
                     "incident_wavelength", "x_pixel_size"]

    # Ensure all required keys exist
    for key in required_keys:
        if key not in metadata:
            logging.error("Missing required metadata key: %s", key)
            raise ValueError(f"Missing required metadata key: {key}")

    # Extract parameters
    beam_center_x = metadata["beam_centre_x"]
    beam_center_y = metadata["beam_centre_y"]
    detector_distance = metadata["detector_distance"]
    wavelength = metadata["incident_wavelength"]
    pixel_size = metadata["x_pixel_size"]

    logging.debug("Metadata extracted: Beam Center (%s, %s), Detector Distance: %s mm, Wavelength: %s Å, Pixel Size: %s mm",
                  beam_center_x, beam_center_y, detector_distance, wavelength, pixel_size)

    if detector_distance == 0:
        logging.critical("Detector distance is zero! This will cause a division error.")
        raise ValueError("Detector distance cannot be zero.")

    # Convert pixel coordinates to mm distances from beam center
    delta_x = (pixel_x - beam_center_x) * pixel_size
    delta_y = (pixel_y - beam_center_y) * pixel_size
    logging.debug("Pixel offsets from beam center: ΔX = %s mm, ΔY = %s mm", delta_x, delta_y)

    # Compute R (distance from beam center to the pixel in mm)
    R = np.hypot(delta_x, delta_y)
    logging.info(f"Computed radial distance: \t\t\t\tR = \t{R:.0f} mm")

    # Compute theta in radians
    two_theta_rad = calculate_two_theta_radians(R, detector_distance)
    two_theta_deg = np.degrees(two_theta_rad)
    logging.info(f"Computed scattering angle: \t\t\tθ = \t{two_theta_deg:.2f}°")

    # Compute resolution using Bragg's Law
    if two_theta_rad == 0:
        resolution = float('inf')
        logging.warning("Theta is zero, resolution is set to infinity.")
    else:
        resolution = wavelength / (2 * np.sin(two_theta_rad / 2 )) # two_theta / 2 = theta
    logging.info(f"Computed resolution: \t\t\t\t\t{resolution:.2f} Å")
    return two_theta_deg, resolution


def calculate_two_theta_radians(R, detector_distance):
    """ calculate_two_theta """
    logging.info(f"calculate_two_theta")
    two_theta_rad = np.arctan(R / detector_distance)
    return two_theta_rad


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
        self.image_inverted = False
        self.show_rings = True  # Default to showing rings
        # Main widget and layout
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)

        # Resolution display
        resolution_layout = QHBoxLayout()
        self.resolution_label = QLabel("Resolution: N/A")
        resolution_layout.addWidget(self.resolution_label)

        self.beam_x_label = QLabel("beam_x: N/A")
        resolution_layout.addWidget(self.beam_x_label)

        self.beam_y_label = QLabel("beam_y: N/A")
        resolution_layout.addWidget(self.beam_y_label)

        self.x_pixel_label = QLabel("x pixel: N/A")
        resolution_layout.addWidget(self.x_pixel_label)

        self.y_pixel_label = QLabel("y pixel: N/A")
        resolution_layout.addWidget(self.y_pixel_label)

        self.two_theta_label= QLabel(f"two theta: N/A degrees")
        resolution_layout.addWidget(self.two_theta_label)

        layout.addLayout(resolution_layout)

        # Checkbox for resolution rings
        self.rings_checkbox = QCheckBox("Show Resolution Rings")
        self.rings_checkbox.setChecked(True)
        self.rings_checkbox.stateChanged.connect(self.toggle_rings)
        layout.addWidget(self.rings_checkbox)

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
        """ Update frame and apply current contrast level """
        if self.dataset is not None:
            # Display the selected frame
            self.display_hdf5_image(start_index)

            # Apply contrast from the slider value
            contrast_value = self.contrast_slider.value()  # Get current slider value
            self.update_contrast(contrast_value)  # Apply contrast adjustment

            # Update UI
            self.frame_label.setText(f"Frame: {start_index}")
            logging.info(f"Frame {start_index} updated with contrast level {contrast_value}.")

    def display_hdf5_image(self, start_index):
        """Display a slice of frames from the HDF5 dataset with improved contrast and no white borders."""
        try:
            if self.dataset is None:
                raise ValueError("No dataset loaded.")

            # Select frame slice
            end_index = min(start_index + self.slice_size, self.num_frames)
            frame_data = np.array(self.dataset[start_index:end_index, :, :])  # Convert to NumPy array

            # Ensure grayscale format
            if frame_data.ndim == 3:
                gray = frame_data
            else:
                gray = cv2.cvtColor(frame_data, cv2.COLOR_RGB2GRAY)

            # Mask non-white areas (considering white as near 255)
            mask = gray < 240  # Pixels below 240 are considered part of the image
            valid_pixels = frame_data[mask]

            # Compute statistics for contrast enhancement
            mean_val = np.mean(valid_pixels)
            std_val = np.std(valid_pixels)
            lower_bound = mean_val - 5 * std_val
            upper_bound = mean_val + 5 * std_val

            # Clip and normalize pixel values
            frame_clipped = np.clip(frame_data, lower_bound, upper_bound)
            p_low, p_high = np.percentile(frame_clipped[mask], (2, 98))  # Percentile-based contrast adjustment
            frame_normalized = np.clip((frame_clipped - p_low) / (p_high - p_low) * 255, 0, 255).astype(np.uint8)

            # Apply Adaptive Histogram Equalization (CLAHE)
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            enhanced_frames = np.array([clahe.apply(frame) for frame in frame_normalized])

            # Apply Gamma Correction
            gamma = 1.2  # Adjustable
            gamma_corrected = np.power(enhanced_frames / 255.0, gamma) * 255
            gamma_corrected = gamma_corrected.astype(np.uint8)

            # Compute the average processed frame
            final_frame = np.mean(gamma_corrected, axis=0).astype(np.uint8)

            # Convert to PIL image for display
            self.current_image = Image.fromarray(final_frame)
            if self.image_inverted:
                self.do_invert_image()
            contrast_value = self.contrast_slider.value()  # Get current slider value
            self.update_contrast(contrast_value)  # Apply contrast adjustment
            self.show_image(self.current_image)

            logging.info(f"Frames {start_index} to {end_index} displayed successfully.")

        except Exception as ex:
            logging.error(f"Error in display_hdf5_image: {ex}")

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
        logging.info(f"show_image: {image}")
        try:
            image = image.convert("RGB")
            width, height = image.size
            data = image.tobytes("raw", "RGB")
            qimage = QImage(data, width, height, 3 * width, QImage.Format_RGB888)
            pixmap = QPixmap.fromImage(qimage)

            if self.show_rings:
                # Draw resolution rings
                painter = QPainter(pixmap)
                pen = QPen(QColor(255, 0, 0), 2)  # Red color, 2 pixels wide
                painter.setPen(pen)
                font = painter.font()
                font.setPointSize(60)
                painter.setFont(font)

                # Calculate radii for resolution rings
                resolutions = [1.0, 2.0, 3.0]  # Ångströms
                radii = []
                for resolution in resolutions:
                    two_theta_rad = np.arcsin(self.incident_wavelength / (2 * resolution))
                    R_mm = self.detector_distance * np.tan(two_theta_rad * 2)
                    R_pixels = R_mm / self.x_pixel_size
                    radii.append(R_pixels)

                # Use beam center for resolution rings
                center = QPoint(int(self.beam_center[0]), int(self.beam_center[1]))

                for i, radius in enumerate(radii):
                    painter.drawEllipse(center, int(radius), int(radius))
                    # Draw label
                    label_pos = QPoint(center.x() + int(radius) + 5, center.y())
                    painter.drawText(label_pos, f"{resolutions[i]} Å")

                painter.end()

            self.image_label.setPixmap(pixmap.scaled(self.image_label.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation))
        except Exception as ex:
            logging.error(f"Error: {ex} occurred")

    def get_origin_resolution(self, painter, center, radii):
        """ 
        get_origin_resolution 
        get the resolution at the origin
        """
        logging.info(f"get_origin_resolution")
        origin  = (0, 0)
        metadata = {
            "beam_centre_x": self.beam_center[0],
            "beam_centre_y": self.beam_center[1],
            "detector_distance": self.detector_distance,
            "incident_wavelength": self.incident_wavelength,
            "x_pixel_size": self.x_pixel_size
        }
        self.get_resolution(origin, metadata)

    def get_resolution(self, point, metadata):
        """ get_resolution """
        logging.info(f"get_resolution")
        self.compute_theta_and_resolution(point[0], point[1], metadata)

    def invert_image(self):
        """Invert the image."""
        logging.info(f"invert_image")
        if not self.image_inverted:
            self.image_inverted = True
        else:
            self.image_inverted = False

        if self.current_image:
            try:
                self.do_invert_image()
            except Exception as ex:
                logging.error(f"Error: {ex} occurred")

    def do_invert_image(self):
        """Perform image inversion."""
        logging.info(f"do_invert_image")
        if self.current_image:
            try:
                inverted_image = ImageOps.invert(self.current_image.convert("RGB"))
                self.current_image = inverted_image
                self.show_image(inverted_image)
            except Exception as ex:
                logging.error(f"Error: {ex} occurred")

    def update_contrast(self, value):
        """Update contrast using NumPy for better performance."""
        logging.info(f"update_contrast: {value}")
        if self.current_image:
            try:
                contrast_factor = value / 100.0

                # Convert PIL image to NumPy array
                img_array = np.array(self.current_image.convert("RGB"), dtype=np.float32)

                # Apply contrast adjustment
                mean = np.mean(img_array, axis=(0, 1), keepdims=True)  # Compute mean per channel
                adjusted_array = mean + contrast_factor * (img_array - mean)  # Contrast formula

                # Clip values to ensure valid range
                adjusted_array = np.clip(adjusted_array, 0, 255).astype(np.uint8)

                # Convert back to PIL image
                adjusted_image = Image.fromarray(adjusted_array)

                # Update the UI
                self.current_image = adjusted_image
                self.show_image(adjusted_image)
                self.contrast_label.setText(f"Contrast: {value}")
            except Exception as ex:
                logging.error(f"Error in update_contrast: {ex}")

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
            # Get display coordinates
            x_display = event.position().x()
            y_display = event.position().y()

            # Calculate scaling factors
            image_width = self.image_label.pixmap().width()
            image_height = self.image_label.pixmap().height()
            dataset_width = self.dataset.shape[2]  # Assuming dataset shape is (frames, height, width)
            dataset_height = self.dataset.shape[1]

            scale_x = dataset_width / image_width
            scale_y = dataset_height / image_height

            # Convert to dataset coordinates
            x_dataset = x_display * scale_x
            y_dataset = y_display * scale_y

            # Update labels
            self.x_pixel_label.setText(f"x pixel: {x_dataset:.0f}")
            self.y_pixel_label.setText(f"y pixel: {y_dataset:.0f}")
            self.beam_x_label.setText(f"beam_x: {self.beam_x:.0f}")
            self.beam_y_label.setText(f"beam_y: {self.beam_y:.0f}")

            # Compute resolution
            metadata = {
                "beam_centre_x": self.beam_center[0],
                "beam_centre_y": self.beam_center[1],
                "detector_distance": self.detector_distance[0],  # Ensure this is a single value
                "incident_wavelength": self.incident_wavelength,
                "x_pixel_size": self.x_pixel_size
            }
            two_theta, resolution = compute_two_theta_and_resolution(x_dataset, y_dataset, metadata)
            self.two_theta_label.setText(f"two theta: {two_theta:0.2f} °")
            self.resolution_label.setText(f"Resolution: {resolution:0.2f} Å")

    def toggle_rings(self, state):
        """ Toggle the visibility of rings on the image """
        self.show_rings = state == Qt.CheckState.Checked
        logging.info(f"Toggle rings: {'ON' if self.show_rings else 'OFF'}")
        if self.current_image:
            self.show_image(self.current_image)  # Refresh display with/without rings


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
