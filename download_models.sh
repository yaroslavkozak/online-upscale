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

# Tile sizes for Real-ESRGAN and Real-CUGAN
REALESRGAN_TILE_SIZES=(32 48 64 96 128 192 256)
REALCUGAN_TILE_SIZES=(32 48 64 96 128 192 256 384 512)

# Real-ESRGAN models
REALESRGAN_MODELS=(anime_fast anime_plus general_fast general_plus)

# Real-CUGAN factors and denoise options
REALCUGAN_FACTORS=(2 4)
REALCUGAN_DENOISE_2=(conservative no-denoise denoise1x denoise2x denoise3x)
REALCUGAN_DENOISE_4=(conservative no-denoise denoise3x)

# Download function for RealESRGAN models
download_realesrgan() {
    local model=$1
    local tile_size=$2
    local dir="public/realesrgan/${model}-${tile_size}"
    mkdir -p "$dir"
    echo "Downloading RealESRGAN ${model} tile_size ${tile_size}..."
    curl -L "${BASE_URL}/realesrgan/${model}-${tile_size}/model.json" -o "${dir}/model.json"
    curl -L "${BASE_URL}/realesrgan/${model}-${tile_size}/group1-shard1of1.bin" -o "${dir}/group1-shard1of1.bin"
}

# Download function for Real-CUGAN models
download_realcugan() {
    local factor=$1
    local denoise=$2
    local tile_size=$3
    local dir="public/realcugan/${factor}x-${denoise}-${tile_size}"
    mkdir -p "$dir"
    echo "Downloading Real-CUGAN ${factor}x ${denoise} tile_size ${tile_size}..."
    curl -L "${BASE_URL}/realcugan/${factor}x-${denoise}-${tile_size}/model.json" -o "${dir}/model.json"
    curl -L "${BASE_URL}/realcugan/${factor}x-${denoise}-${tile_size}/group1-shard1of1.bin" -o "${dir}/group1-shard1of1.bin"
}

# Download all RealESRGAN models for all tile sizes
for model in "${REALESRGAN_MODELS[@]}"; do
  for tile in "${REALESRGAN_TILE_SIZES[@]}"; do
    download_realesrgan "$model" "$tile"
  done
done

# Download all Real-CUGAN models for all tile sizes and denoise options
for factor in "${REALCUGAN_FACTORS[@]}"; do
  if [ "$factor" == "2" ]; then
    denoise_list=("${REALCUGAN_DENOISE_2[@]}")
  else
    denoise_list=("${REALCUGAN_DENOISE_4[@]}")
  fi
  for denoise in "${denoise_list[@]}"; do
    for tile in "${REALCUGAN_TILE_SIZES[@]}"; do
      download_realcugan "$factor" "$denoise" "$tile"
    done
  done
done

echo "All models downloaded successfully!" 