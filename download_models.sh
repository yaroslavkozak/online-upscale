#!/bin/bash

# Create directories for RealESRGAN models
mkdir -p public/realesrgan/anime_fast-32
mkdir -p public/realesrgan/anime_plus-32
mkdir -p public/realesrgan/general_fast-32
mkdir -p public/realesrgan/general_plus-32

# Create directories for Real-CUGAN models
mkdir -p public/realcugan/2x-conservative-32
mkdir -p public/realcugan/2x-no-denoise-32
mkdir -p public/realcugan/2x-denoise1x-32
mkdir -p public/realcugan/2x-denoise2x-32
mkdir -p public/realcugan/2x-denoise3x-32
mkdir -p public/realcugan/4x-conservative-32
mkdir -p public/realcugan/4x-no-denoise-32
mkdir -p public/realcugan/4x-denoise3x-32

# Base URL for the demo site
BASE_URL="https://cappuccino.moe"

# Download function for RealESRGAN models
download_realesrgan() {
    local model=$1
    local tile_size=$2
    local dir="public/realesrgan/${model}-${tile_size}"
    
    echo "Downloading RealESRGAN ${model} model..."
    curl -L "${BASE_URL}/realesrgan/${model}-${tile_size}/model.json" -o "${dir}/model.json"
    curl -L "${BASE_URL}/realesrgan/${model}-${tile_size}/group1-shard1of1.bin" -o "${dir}/group1-shard1of1.bin"
}

# Download function for Real-CUGAN models
download_realcugan() {
    local factor=$1
    local denoise=$2
    local tile_size=$3
    local dir="public/realcugan/${factor}x-${denoise}-${tile_size}"
    
    echo "Downloading Real-CUGAN ${factor}x ${denoise} model..."
    curl -L "${BASE_URL}/realcugan/${factor}x-${denoise}-${tile_size}/model.json" -o "${dir}/model.json"
    curl -L "${BASE_URL}/realcugan/${factor}x-${denoise}-${tile_size}/group1-shard1of1.bin" -o "${dir}/group1-shard1of1.bin"
}

# Download all RealESRGAN models
download_realesrgan "anime_fast" "32"
download_realesrgan "anime_plus" "32"
download_realesrgan "general_fast" "32"
download_realesrgan "general_plus" "32"

# Download all Real-CUGAN models
download_realcugan "2" "conservative" "32"
download_realcugan "2" "no-denoise" "32"
download_realcugan "2" "denoise1x" "32"
download_realcugan "2" "denoise2x" "32"
download_realcugan "2" "denoise3x" "32"
download_realcugan "4" "conservative" "32"
download_realcugan "4" "no-denoise" "32"
download_realcugan "4" "denoise3x" "32"

echo "All models downloaded successfully!" 