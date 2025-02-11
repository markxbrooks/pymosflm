import argparse
import os
import sys

import h5py
from PySide6.QtWidgets import QApplication, QMainWindow, QFileDialog, QVBoxLayout, QHBoxLayout, QLabel, QSlider, QPushButton, QTextEdit, QWidget
from PySide6.QtGui import QImage, QPixmap, QPalette, QColor
from PySide6.QtCore import Qt, QSize

from PIL import Image, ImageTk, ImageOps, ImageEnhance
import fabio  # Import FabIO
import matplotlib.pyplot as plt
import cv2
import numpy as np

# Set environment variables
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
    print("ccp4i2 mode: ON")

# Fastload mode setup
fastload = os.getenv('FASTLOAD', '0') == '1'
if fastload:
    print("fastload mode: ON")


class IMosflmApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("iMosflm")
        self.setGeometry(100, 100, 800, 1000)
        self.current_image = None

        # Main widget and layout
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)

        # Image display
        self.image_label = QLabel()
        layout.addWidget(self.image_label)

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

        # Contrast slider
        self.contrast_slider = QSlider(Qt.Horizontal)
        self.contrast_slider.setRange(50, 300)
        self.contrast_slider.setValue(100)
        self.contrast_slider.valueChanged.connect(self.update_contrast)
        layout.addWidget(self.contrast_slider)

    def open_file(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Open Image", "", "Image Files (*.jpg *.png *.gif *.tif *.tiff *.cbf *.h5)")
        if file_path:
            if file_path.lower().endswith('.cbf'):
                self.display_cbf_image(file_path)
            if file_path.lower().endswith('.h5'):
                self.display_cbf_image(file_path)
            else:
                self.display_image(file_path)

    def display_image(self, file_path):
        image = Image.open(file_path)
        self.current_image = image
        self.show_image(image)

    def display_cbf_image(self, file_path):
        try:
            cbf_image = fabio.open(file_path)
            data = cbf_image.data
            image = Image.fromarray(data)
            self.current_image = image.convert("L")
            self.show_image(self.current_image)
        except Exception as e:
            print(f"Failed to load CBF image: {e}")

    def display_hdf5_image(self, image_path):
        """Load and display an HDF5 image."""
        try:
            with h5py.File(image_path, "r") as f:
                # Print available datasets
                print("Available datasets:", list(f.keys()))

                # Attempt to find an image dataset
                dataset_path = "/entry/data/data"  # Change if necessary
                if dataset_path not in f:
                    raise ValueError(f"Dataset '{dataset_path}' not found in {image_path}")

                # Load image data
                image_data = f[dataset_path][...]

                # Convert to 8-bit grayscale image
                image_data = np.array(image_data, dtype=np.uint8)
                pil_image = Image.fromarray(image_data)
                # Store and display the image
                self.current_image = pil_image
                self.show_image(self.current_image)
        except Exception as ex:
            print(f"Error {ex} occurred")

    def show_image(self, image):
        image = image.convert("RGB")
        width, height = image.size
        data = image.tobytes("raw", "RGB")
        qimage = QImage(data, width, height, 3 * width, QImage.Format_RGB888)
        pixmap = QPixmap.fromImage(qimage)
        self.image_label.setPixmap(pixmap.scaled(self.image_label.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation))

    def invert_image(self):
        if self.current_image:
            inverted_image = ImageOps.invert(self.current_image.convert("RGB"))
            self.current_image = inverted_image
            self.show_image(inverted_image)

    def update_contrast(self, value):
        if self.current_image:
            contrast_factor = value / 100.0
            enhancer = ImageEnhance.Contrast(self.current_image)
            adjusted_image = enhancer.enhance(contrast_factor)
            self.current_image = adjusted_image
            self.show_image(adjusted_image)

    def show_histogram(self):
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
        if self.current_image:
            self.show_image(self.current_image)
        super().resizeEvent(event)

def parse_arguments():
    parser = argparse.ArgumentParser(description='iMosflm Application')
    parser.add_argument('--ccp4i2', action='store_true', help='Autosaves an iMosflm session file upon exit')
    parser.add_argument('--debug', '-d', action='store_true', help='Creates a large output file for debugging purposes')
    parser.add_argument('--expert', '-e', action='store_true', help='Permits access to advanced detector settings')
    parser.add_argument('--fastload', '-f', action='store_true', help='Attempt to speed loading of many images offline')
    parser.add_argument('--version', '-v', action='store_true', help='Displays the program version and required Mosflm version, then exits')
    # Remove the explicit --help argument
    return parser.parse_args()

def main():
    args = parse_arguments()

    # Set environment variables based on arguments
    if args.ccp4i2:
        os.environ['CCP4I2'] = '1'
        print("* CCP4i2 mode on - be VERY sure you want this")

    if args.debug:
        os.environ['MOSFLM_DEBUG'] = '1'
        print("* full debugging turned on")

    if args.expert:
        os.environ['EXPERTDETECTORSETTINGS'] = '1'
        print("* Expert mode on - be VERY sure you want this")

    if args.fastload:
        os.environ['FASTLOAD'] = '1'
        print("* FASTLOAD mode on")

    if args.version:
        print(f"* {os.environ.get('IMOSFLM_VERSION', 'Unknown version')}")
        sys.exit()

    # Initialize and run the application
    app = QApplication(sys.argv)
    window = IMosflmApp()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()    