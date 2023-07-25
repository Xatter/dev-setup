#!/bin/bash

# Decompress
unzip Source_Code_Pro.zip

# Install
cp static/* ~/Library/Fonts

# Cleanup
rm -rf static
rm SourceCodePro-VariableFont_wght.ttf  
rm SourceCodePro-Italic-VariableFont_wght.ttf  
rm OFL.txt                 
rm README.txt  
