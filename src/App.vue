<!--
  Developed by Yaroslav Kozak
  https://github.com/yaroslavkozak
-->
<template>
  <!-- <div v-if="isDragOver" class="drag-mask">Drop your image here</div> -->
  <div
    ref="canvasContainer"
    class="canvas-container"
    :class="{
      'canvas-container': true,
      bg: true,
      dark: imgLoaded || batchQueue.length > 0,
      'drag-over': isDragOver,
      'batch-mode': batchQueue.length > 0
    }"
    @drop.prevent="handleDrop"
    @dragover.prevent="isDragOver = true"
    @dragleave="
      (e) => {
        if (!e.currentTarget.contains(e.relatedTarget)) {
          isDragOver = false;
        }
      }
    "
    @mousedown="startDragging"
    @mouseup="stopDragging"
    @mousemove="dragImage"
    @wheel="resizeImage"
    @touchstart="touchStart"
    @touchmove="touchMove"
    @touchend="touchEnd"
  >
    <!-- Hidden canvases for processing -->
    <canvas ref="canvas" style="display: none"></canvas>
    <canvas ref="imgCanvas" style="display: none"></canvas>

    <!-- Single Image View -->
    <template v-if="!batchQueue.length">
      <div v-if="!imgLoaded && !isDragOver" class="title">
        <img src="/logo.svg" alt="App Logo" class="app-logo">

        <div>Upscale Images Online</div>
        
      </div>
      <canvas ref="canvas"></canvas>
      <button
        v-show="!imgLoaded"
        class="upload-button"
        @click="handleClick"
        :style="upload_button_style"
      >
        <div class="upload-container">
          <svg viewBox="0 0 24 24">
            <path
              d="M19 7v3h-2V7h-3V5h3V2h2v3h3v2h-3zm-3 4V8h-3V5H5a2 2 0 00-2 2v12c0 1.1.9 2 2 2h12a2 2 0 002-2v-8h-3zM5 19l3-4 2 3 3-4 4 5H5z"
              fill="white"
            ></path>
          </svg>
        </div>
      </button>
      <button v-show="imgLoaded" class="goback" @click="reloadPage">
        <svg width="24" height="24" viewBox="0 0 1024 1024">
          <g fill="rgba(255, 255, 255, 1)" stroke-width="50" stroke="rgba(255, 255, 255, 1)">
            <path d="M511.4 175.3l-31.6 31.6-74.8 74.8-87.7 87.7-71.5 71.5-20.1 20.1c-7.1 7.1-13.9 14.3-18.1 23.7-11.2 25.4-6 53.9 13.6 73.7l13.2 13.2 62.7 62.7 86.8 86.8 80.8 80.8 44.7 44.7 2.1 2.1c6.7 6.7 18.9 7.2 25.5 0 6.6-7.2 7.1-18.3 0-25.5l-30.9-30.9-73.8-73.8-87.1-87.1-71.7-71.7-21.1-21.1-5.3-5.3-1.1-1.1-0.1-0.1c-0.3-0.3-3.9-4.4-2.4-2.6 1.3 1.7-0.1-0.2-0.3-0.5-0.8-1.2-1.5-2.4-2.2-3.6-0.3-0.6-0.7-1.2-1-1.9-0.3-0.6-1.3-3.3-0.5-1 0.7 2.3-0.7-2.4-0.9-3.1-0.4-1.4-1.7-6-0.7-2-0.5-1.9-0.3-4.2-0.3-6.2 0-0.1 0.3-4.8 0.3-4.8 0.5 0.1-0.7 3.6 0 0.7l0.6-2.7c0.3-1.2 2.3-6.2 0.5-2.2 0.8-1.7 1.6-3.4 2.6-5 0.6-0.9 4-5.1 1.3-2.2 1-1.1 1.9-2.2 3-3.3l0.2-0.2 1.2-1.2 14.3-14.3 63.6-63.6 86-86 79.8-79.8 44-44 2.1-2.1c6.7-6.7 7.2-18.9 0-25.5-7.4-6.3-18.6-6.8-25.7 0.3z"></path>
            <path d="M804.6 494H432.9c-17.2 0-34.5-0.5-51.7 0h-0.7c-9.4 0-18.4 8.3-18 18 0.4 9.8 7.9 18 18 18h371.7c17.2 0 34.5 0.5 51.7 0h0.7c9.4 0 18.4-8.3 18-18-0.5-9.8-8-18-18-18z"></path>
          </g>
        </svg>
      </button>
      <a href="https://github.com/xororz/web-realesrgan" v-show="imgLoaded" target="_blank">
        <img src="/gh.png" alt="github" class="github" />
      </a>
      <div class="floating-menu" :style="menu_style" @mousedown.stop>
        <div>
          <div class="info" v-if="info">{{ info }}</div>
          <div class="progressbar" v-if="isProcessing || isDone">
            <progress max="100" :value="progress"></progress>
          </div>
        </div>
        <div class="opt" v-if="!isProcessing && !isDone">
          <div>
            <span class="description">Type</span>
            <select v-model="model_type">
              <option value="realesrgan">Real-ESRGAN</option>
              <option value="realcugan">Real-CUGAN</option>
            </select>
          </div>
          <div v-if="model_type === 'realesrgan'">
            <div>
              <span class="description">Model</span>
              <select v-model="model">
                <option
                  v-for="modelOption in model_config.realesrgan.model"
                  :key="modelOption"
                  :value="modelOption"
                >
                  {{ modelOption }}
                </option>
              </select>
            </div>
            <div>
              <span class="description">Scale</span>
              <select v-model="factor">
                <option
                  v-for="factorOption in model_config.realesrgan.factor"
                  :key="factorOption"
                  :value="factorOption"
                >
                  {{ factorOption }}
                </option>
              </select>
            </div>
            <div>
              <span class="description">Tile Size</span>
              <select v-model="tile_size">
                <option
                  v-for="tileSizeOption in model_config.realesrgan.tile_size"
                  :key="tileSizeOption"
                  :value="tileSizeOption"
                >
                  {{ tileSizeOption }}
                </option>
              </select>
            </div>
          </div>
          <div v-else-if="model_type === 'realcugan'">
            <div>
              <span class="description">Denoise</span>
              <select v-model="denoise">
                <option
                  v-for="denoiseOption in model_config.realcugan.denoise[factor]"
                  :key="denoiseOption"
                  :value="denoiseOption"
                >
                  {{ denoiseOption }}
                </option>
              </select>
            </div>
            <div>
              <span class="description">Scale</span>
              <select v-model="factor">
                <option
                  v-for="factorOption in model_config.realcugan.factor"
                  :key="factorOption"
                  :value="factorOption"
                >
                  {{ factorOption }}
                </option>
              </select>
            </div>
            <div>
              <span class="description">Tile Size</span>
              <select v-model="tile_size">
                <option
                  v-for="tileSizeOption in model_config.realcugan.tile_size"
                  :key="tileSizeOption"
                  :value="tileSizeOption"
                >
                  {{ tileSizeOption }}
                </option>
              </select>
            </div>
          </div>
          <div>
            <span class="description">Overlap</span>
            <select v-model="min_lap">
              <option>0</option>
              <option>4</option>
              <option>8</option>
              <option>12</option>
              <option>16</option>
              <option>20</option>
            </select>
          </div>
          <div>
            <span class="description">Run on</span>
            <select v-model="backend">
              <option value="webgl">WebGL</option>
              <option value="webgpu">WebGPU</option>
            </select>
          </div>
        </div>
        <div>
          <div>
            <button class="question-button" v-if="!isProcessing && !isDone">
              <a
                href="https://github.com/xororz/web-realesrgan/?tab=readme-ov-file#best-practice"
                target="_blank"
              >
                <svg
                  viewBox="0 0 15 15"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="#fff"
                >
                  <path
                    fill-rule="evenodd"
                    clip-rule="evenodd"
                    d="M7.5 1a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13zm0 12a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11zm1.55-8.42a1.84 1.84 0 0 0-.61-.42A2.25 2.25 0 0 0 7.53 4a2.16 2.16 0 0 0-.88.17c-.239.1-.45.254-.62.45a1.89 1.89 0 0 0-.38.62 3 3 0 0 0-.15.72h1.23a.84.84 0 0 1 .506-.741.72.72 0 0 1 .304-.049.86.86 0 0 1 .27 0 .64.64 0 0 1 .22.14.6.6 0 0 1 .16.22.73.73 0 0 1 .06.3c0 .173-.037.343-.11.5a2.4 2.4 0 0 1-.27.46l-.35.42c-.12.13-.24.27-.35.41a2.33 2.33 0 0 0-.27.45 1.18 1.18 0 0 0-.1.5v.66H8v-.49a.94.94 0 0 1 .11-.42 3.09 3.09 0 0 1 .28-.41l.36-.44a4.29 4.29 0 0 0 .36-.48 2.59 2.59 0 0 0 .28-.55 1.91 1.91 0 0 0 .11-.64 2.18 2.18 0 0 0-.1-.67 1.52 1.52 0 0 0-.35-.55zM6.8 9.83h1.17V11H6.8V9.83z"
                  />
                </svg>
              </a>
            </button>
          </div>
          <button
            class="run-button"
            v-if="!isProcessing && !isDone"
            @click="startTask"
          >
            <svg viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z" fill="rgba(255, 255, 255, 1)"></path>
            </svg>
          </button>
        </div>
        <button class="save-button" v-if="isDone" @click="saveImage">
          <svg width="22" viewBox="0 -4 23.9 30">
            <path
              fill="#fff"
              d="M6.6 2.7h-4v13.2h2.7A2.7 2.7 0 018 18.6a2.7 2.7 0 002.6 2.6h2.7a2.7 2.7 0 002.6-2.6 2.7 2.7 0 012.7-2.7h2.6V2.7h-4a1.3 1.3 0 110-2.7h4A2.7 2.7 0 0124 2.7v18.5a2.7 2.7 0 01-2.7 2.7H2.7A2.7 2.7 0 010 21.2V2.7A2.7 2.7 0 012.7 0h4a1.3 1.3 0 010 2.7zm4 7.4V1.3a1.3 1.3 0 112.7 0v8.8L15 8.4a1.3 1.3 0 011.9 1.8l-4 4a1.3 1.3 0 01-1.9 0l-4-4A1.3 1.3 0 019 8.4z"
            ></path>
          </svg>
        </button>
      </div>
      <div
        class="dragLine"
        ref="dragLine"
        v-show="isDone"
        @mousedown.stop="startDraggingLine"
        @mousemove.stop="dragLine"
      >
        <div class="dragBall">
          <svg width="30" viewBox="0 0 27 20">
            <path fill="#ff3484" d="M9.6 0L0 9.6l9.6 9.6z"></path>
            <path fill="#5fb3e5" d="M17 19.2l9.5-9.6L16.9 0z"></path>
          </svg>
        </div>
      </div>
      <div v-if="!imgLoaded & !isDragOver" class="bottom-svg">
        <svg width="100%" viewBox="0 0 1920 140" class="_top-wave_vzxu7_106">
          <path
            fill="#76c8fe"
            d="M1920 0l-107 28c-106 29-320 85-533 93-213 7-427-36-640-50s-427 0-533 7L0 85v171h1920z"
            class="_sub-wave_vzxu7_117"
          ></path>
          <path
            fill="#009aff"
            d="M0 129l64-26c64-27 192-81 320-75 128 5 256 69 384 64 128-6 256-80 384-91s256 43 384 70c128 26 256 26 320 26h64v96H0z"
            class="_main-wave_vzxu7_113"
          ></path>
        </svg>
        <div class="demo">
          <div>No ideas? Try one of these:</div>
          <br />
          <div>
            <img class="demoimg" src="/demo/1.jpg" alt="demo" @click="testdemo" />
            <img class="demoimg" src="/demo/2.jpg" alt="demo" @click="testdemo" />
            <img class="demoimg" src="/demo/3.jpg" alt="demo" @click="testdemo" />
          </div>
        </div>
      </div>
    </template>

    <!-- Batch Processing View -->
    <template v-if="!compareItem">
      <div class="batch-container">
        <!-- Header Section -->
        <div class="batch-header">
          <div class="header-left">
            <h2>Batch Processing</h2>
            <div class="batch-stats">
              <div class="stat-item">
                <span class="stat-value">{{ batchQueue.length }}</span>
                <span class="stat-label">Total</span>
              </div>
              <div class="stat-item">
                <span class="stat-value">{{ completedCount }}</span>
                <span class="stat-label">Done</span>
              </div>
              <div class="stat-item">
                <span class="stat-value">{{ processingCount }}</span>
                <span class="stat-label">Processing</span>
              </div>
              <div class="stat-item">
                <span class="stat-value">{{ failedCount }}</span>
                <span class="stat-label">Failed</span>
              </div>
            </div>
          </div>
          <div class="header-actions">
            <button @click="downloadAll" :disabled="!hasCompletedItems" class="action-button primary">
              <svg viewBox="0 0 24 24" width="18" height="18">
                <path fill="currentColor" d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/>
              </svg>
              Download All
            </button>
            <button @click="clearQueue" class="action-button secondary">
              <svg viewBox="0 0 24 24" width="18" height="18">
                <path fill="currentColor" d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
              </svg>
              Clear Queue
            </button>
          </div>
        </div>

        <!-- Options Section -->
        <div class="batch-options">
          <div class="options-header">
            <h3>Upscaling Settings</h3>
            <button 
              @click="startBatchProcessing" 
              class="start-button"
              :disabled="isProcessingBatch || !batchQueue.length"
            >
              <svg v-if="!isProcessingBatch" viewBox="0 0 24 24" width="18" height="18">
                <path fill="currentColor" d="M8 5v14l11-7z"/>
              </svg>
              {{ isProcessingBatch ? 'Processing...' : 'Start Processing' }}
            </button>
          </div>
          <div class="options-grid">
            <div class="option-group">
              <label>Type</label>
              <select v-model="model_type" class="styled-select">
                <option value="realesrgan">Real-ESRGAN</option>
                <option value="realcugan">Real-CUGAN</option>
              </select>
            </div>
            <div v-if="model_type === 'realesrgan'" class="option-group">
              <label>Model</label>
              <select v-model="model" class="styled-select">
                <option v-for="modelOption in model_config.realesrgan.model" 
                        :key="modelOption" 
                        :value="modelOption">
                  {{ modelOption }}
                </option>
              </select>
            </div>
            <div v-else-if="model_type === 'realcugan'" class="option-group">
              <label>Denoise</label>
              <select v-model="denoise" class="styled-select">
                <option v-for="denoiseOption in model_config.realcugan.denoise[factor]" 
                        :key="denoiseOption" 
                        :value="denoiseOption">
                  {{ denoiseOption }}
                </option>
              </select>
            </div>
            <div class="option-group">
              <label>Scale</label>
              <select v-model="factor" class="styled-select">
                <option v-for="factorOption in model_config[model_type].factor" 
                        :key="factorOption" 
                        :value="factorOption">
                  {{ factorOption }}x
                </option>
              </select>
            </div>
            <div class="option-group">
              <label>Tile Size</label>
              <select v-model="tile_size" class="styled-select">
                <option v-for="tileSizeOption in model_config[model_type].tile_size" 
                        :key="tileSizeOption" 
                        :value="tileSizeOption">
                  {{ tileSizeOption }}
                </option>
              </select>
            </div>
            <div class="option-group">
              <label>Overlap</label>
              <select v-model="min_lap" class="styled-select">
                <option v-for="lap in [0, 4, 8, 12, 16, 20]" :key="lap" :value="lap">
                  {{ lap }}
                </option>
              </select>
            </div>
            <div class="option-group">
              <label>Backend</label>
              <select v-model="backend" class="styled-select">
                <option value="webgl">WebGL</option>
                <option value="webgpu">WebGPU</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Images Grid -->
        <div class="batch-grid">
          <div v-for="(item, index) in batchQueue" 
               :key="index" 
               class="batch-item"
               :class="item.status">
            <div class="image-container">
              <img :src="item.previewUrl" class="preview-image" />
              <div class="image-dark-overlay"></div>
              <div class="status-overlay">
                <div class="status-content">
                  <div v-if="item.status === 'processing'" class="progress-container">
                    <span class="progress-text">{{ Math.round(item.progress || 0) }}%</span>
                  </div>
                  <span class="status-text">{{ item.status }}</span>
                  <span v-if="item.error" class="error-message">{{ item.error }}</span>
                  <div v-if="item.status === 'done'" class="status-actions">
                    <button 
                      @click="downloadSingle(item)"
                      class="action-button small download-overlay-btn"
                    >
                      <svg viewBox="0 0 24 24" width="16" height="16">
                        <path fill="currentColor" d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/>
                      </svg>
                      Download
                    </button>
                    <button 
                      @click="compareBatchItem(item)" 
                      class="action-button small compare-btn"
                    >
                      <svg viewBox="0 0 24 24" width="16" height="16">
                        <path fill="currentColor" d="M10 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h5v2h2V1h-2v2zm0 15H5l5-6v6zm9-15h-5v2h5v13l-5-6v9h5c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z"/>
                      </svg>
                      Compare
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <div class="item-info">
              <!-- <span class="filename">{{ item.file.name }}</span> -->
              <div class="item-actions">
                <button 
                  v-if="item.status === 'error'" 
                  @click="retryItem(item)"
                  class="action-button small"
                >
                  <svg viewBox="0 0 24 24" width="16" height="16">
                    <path fill="currentColor" d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/>
                  </svg>
                  Retry
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Single image comparison view for compareItem -->
    <template v-if="compareItem">
      <div class="single-compare-view">
        <button class="goback" @click="compareItem = null">
          <svg width="24" height="24" viewBox="0 0 1024 1024">
            <g fill="rgba(255, 255, 255, 1)" stroke-width="50" stroke="rgba(255, 255, 255, 1)">
              <path d="M511.4 175.3l-31.6 31.6-74.8 74.8-87.7 87.7-71.5 71.5-20.1 20.1c-7.1 7.1-13.9 14.3-18.1 23.7-11.2 25.4-6 53.9 13.6 73.7l13.2 13.2 62.7 62.7 86.8 86.8 80.8 80.8 44.7 44.7 2.1 2.1c6.7 6.7 18.9 7.2 25.5 0 6.6-7.2 7.1-18.3 0-25.5l-30.9-30.9-73.8-73.8-87.1-87.1-71.7-71.7-21.1-21.1-5.3-5.3-1.1-1.1-0.1-0.1c-0.3-0.3-3.9-4.4-2.4-2.6 1.3 1.7-0.1-0.2-0.3-0.5-0.8-1.2-1.5-2.4-2.2-3.6-0.3-0.6-0.7-1.2-1-1.9-0.3-0.6-1.3-3.3-0.5-1 0.7 2.3-0.7-2.4-0.9-3.1-0.4-1.4-1.7-6-0.7-2-0.5-1.9-0.3-4.2-0.3-6.2 0-0.1 0.3-4.8 0.3-4.8 0.5 0.1-0.7 3.6 0 0.7l0.6-2.7c0.3-1.2 2.3-6.2 0.5-2.2 0.8-1.7 1.6-3.4 2.6-5 0.6-0.9 4-5.1 1.3-2.2 1-1.1 1.9-2.2 3-3.3l0.2-0.2 1.2-1.2 14.3-14.3 63.6-63.6 86-86 79.8-79.8 44-44 2.1-2.1c6.7-6.7 7.2-18.9 0-25.5-7.4-6.3-18.6-6.8-25.7 0.3z"></path>
              <path d="M804.6 494H432.9c-17.2 0-34.5-0.5-51.7 0h-0.7c-9.4 0-18.4 8.3-18 18 0.4 9.8 7.9 18 18 18h371.7c17.2 0 34.5 0.5 51.7 0h0.7c9.4 0 18.4-8.3 18-18-0.5-9.8-8-18-18-18z"></path>
            </g>
          </svg>
        </button>
        <!-- Comparison slider and dragLine for compareItem -->
        <canvas ref="canvas"></canvas>
        <div class="dragLine" ref="dragLine" v-show="isDone" @mousedown.stop="startDraggingLine" @mousemove.stop="dragLine">
          <div class="dragBall">
            <svg width="30" viewBox="0 0 27 20">
              <path fill="#ff3484" d="M9.6 0L0 9.6l9.6 9.6z"></path>
              <path fill="#5fb3e5" d="M17 19.2l9.5-9.6L16.9 0z"></path>
            </svg>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script>
import Img from "./image";
import Module from "./imghelper";
import JSZip from 'jszip';

export default {
  data() {
    return {
      dragging: false,
      touching: false,
      imgX: 0,
      imgY: 0,
      imgScale: 1,
      imgInitScale: 1,
      linePosition: 0,
      drawLine: false,
      draggingLine: false,
      imgLoaded: false,
      dpr: window.devicePixelRatio || 1,
      imgName: "output",
      img: new Image(),
      processedImg: new Image(),
      hasAlpha: false,
      touchStartImgX: null,
      touchStartImgY: null,
      touchStartX: null,
      touchStartY: null,
      touchStartDistance: null,
      imgScaleStart: 1,

      imgLoaded: false,
      input: null,
      output: null,
      isDragOver: false,
      isProcessing: false,
      isDone: false,
      progress: 0,
      model_type: "realcugan",
      model_config: {
        realesrgan: {
          model: ["anime_fast", "anime_plus", "general_fast", "general_plus"],
          factor: [4],
          tile_size: [32, 48, 64, 96, 128, 192, 256],
        },
        realcugan: {
          // factor: [2, 3, 4],
          factor: [2, 4],
          denoise: {
            2: [
              "conservative",
              "no-denoise",
              "denoise1x",
              "denoise2x",
              "denoise3x",
            ],
            3: ["conservative", "denoise3x"],
            4: ["conservative", "no-denoise", "denoise3x"],
          },
          tile_size: [32, 48, 64, 96, 128, 192, 256, 384, 512],
        },
      },
      model: "anime_plus",
      factor: 4,
      denoise: "conservative",
      tile_size: 64,
      min_lap: 12,
      save_quality: 92,
      backend: "webgl",
      info: "",
      worker: new Worker(new URL("./worker.js", import.meta.url), {
        type: "module",
      }),
      wasmModule: null,
      batchQueue: [], // Array of {file: File, status: 'pending'|'processing'|'done'|'error', result: Blob|null, progress: number}
      isProcessingBatch: false,
      circumference: 2 * Math.PI * 20, // For r=20 in the progress ring
      compareItem: null,
      compareOriginalImg: null,
      compareUpscaledImg: null,
    };
  },
  watch: {
    model() {
      localStorage.setItem("model", this.model);
    },
    backend() {
      localStorage.setItem("backend", this.backend);
    },
    factor() {
      localStorage.setItem("factor", this.factor);
      if (
        !this.model_config.realcugan.denoise[this.factor].includes(this.denoise)
      ) {
        this.denoise = this.model_config.realcugan.denoise[this.factor][0];
      }
    },
    denoise() {
      localStorage.setItem("denoise", this.denoise);
    },
    tile_size() {
      localStorage.setItem("tile_size", this.tile_size);
    },
    min_lap() {
      localStorage.setItem("min_lap", this.min_lap);
    },
    model_type() {
      localStorage.setItem("model_type", this.model_type);
      if (this.model_type === "realesrgan") {
        if (!this.model_config.realesrgan.model.includes(this.model)) {
          this.model = "anime_plus";
        }
        if (!this.model_config.realesrgan.tile_size.includes(this.tile_size)) {
          this.tile_size = 64;
        }
        this.factor = 4;
      } else {
      }
    },
    compareItem(newVal, oldVal) {
      if (!newVal) {
        if (this.compareOriginalImg && this.compareOriginalImg.src) {
          URL.revokeObjectURL(this.compareOriginalImg.src);
        }
        if (this.compareUpscaledImg && this.compareUpscaledImg.src) {
          URL.revokeObjectURL(this.compareUpscaledImg.src);
        }
        this.compareOriginalImg = null;
        this.compareUpscaledImg = null;
      }
    },
  },
  computed: {
    menu_style() {
      if (this.imgLoaded) {
        if (this.isProcessing || this.isDone) {
          return {
            height: "60px",
          };
        }
        return {
          opacity: 1,
        };
      } else {
        return {
          opacity: 0,
          height: "150px",
          transition: "all 0s ease",
        };
      }
    },
    upload_button_style() {
      if (this.isDragOver) {
        return {
          width: "256px",
          height: "256px",
          "background-color": "pink",
        };
      }
    },
    hasCompletedItems() {
      return this.batchQueue.some(item => item.status === 'done');
    },
    completedCount() {
      return this.batchQueue.filter(item => item.status === 'done').length;
    },
    processingCount() {
      return this.batchQueue.filter(item => item.status === 'processing').length;
    },
    failedCount() {
      return this.batchQueue.filter(item => item.status === 'error').length;
    }
  },
  mounted() {
    this.model_type = localStorage.getItem("model_type") || "realcugan";
    this.model = localStorage.getItem("model") || "anime_plus";
    this.factor = Number(localStorage.getItem("factor")) || 4;
    this.denoise = localStorage.getItem("denoise") || "conservative";
    this.tile_size = Number(localStorage.getItem("tile_size")) || 64;
    this.min_lap = Number(localStorage.getItem("min_lap")) || 12;
    this.backend = localStorage.getItem("backend") || "webgl";
    window.addEventListener("resize", this.handleResize);
    this.initializeCanvas();
    this.linePosition = this.$refs.canvas.width * 2;
    this.$refs.dragLine.style.left = this.linePosition / this.dpr + "px";
    (async () => {
      await Module();
    })();
  },
  beforeDestroy() {
    window.removeEventListener("resize", this.handleResize);
  },
  methods: {
    initializeCanvas() {
      this.updateCanvasSize();
    },
    updateCanvasSize() {
      const container = this.$refs.canvasContainer;
      const canvas = this.$refs.canvas;
      if (this.imgLoaded) {
        this.imgX =
          ((this.imgX + (this.img.width * this.imgScale) / 2) / canvas.width) *
            container.offsetWidth *
            this.dpr -
          (this.img.width * this.imgScale) / 2;
        this.imgY =
          ((this.imgY + (this.img.height * this.imgScale) / 2) /
            canvas.height) *
            container.offsetHeight *
            this.dpr -
          (this.img.height * this.imgScale) / 2;
        
        // Only update line position if we're in single image mode
        if (!this.batchQueue.length && this.$refs.dragLine) {
          this.linePosition =
            (this.linePosition / canvas.width) * container.offsetWidth * this.dpr;
          this.$refs.dragLine.style.left = this.linePosition / this.dpr + "px";
        }
      }
      canvas.width = container.offsetWidth * this.dpr;
      canvas.height = container.offsetHeight * this.dpr;
      canvas.style.width = `${container.offsetWidth}px`;
      canvas.style.height = `${container.offsetHeight}px`;
      this.drawImage();
    },
    handleResize() {
      this.updateCanvasSize();
    },
    loadImg(src) {
      return new Promise((resolve, reject) => {
        this.img.src = src;
        this.img.onload = async () => {
          try {
            // Check for valid dimensions
            if (this.img.width <= 0 || this.img.height <= 0) {
              throw new Error('Invalid image dimensions');
            }

            // Only update UI state if not in compare mode
            if (!this.compareItem) {
              this.imgLoaded = true;
              this.drawLine = true;
            }

            let wasmModule = await Module();
            this.wasmModule = wasmModule;
            const imgCanvas = this.$refs.imgCanvas;
            
            // Set canvas dimensions
            imgCanvas.width = this.img.width;
            imgCanvas.height = this.img.height;
            
            const imgCtx = imgCanvas.getContext("2d", { willReadFrequently: true });
            if (!imgCtx) {
              throw new Error('Failed to get canvas context');
            }

            // Clear canvas before drawing
            imgCtx.clearRect(0, 0, imgCanvas.width, imgCanvas.height);
            imgCtx.drawImage(this.img, 0, 0);

            // Get image data with bounds checking
            const imageData = imgCtx.getImageData(0, 0, this.img.width, this.img.height);
            if (!imageData || !imageData.data) {
              throw new Error('Failed to get image data');
            }

            this.input = new Img(this.img.width, this.img.height, imageData.data);
            const numPixels = this.input.width * this.input.height;
            const bytesPerImage = numPixels * 4;

            // Check for valid memory allocation
            if (bytesPerImage <= 0) {
              throw new Error('Invalid image size');
            }

            let sourcePtr = wasmModule._malloc(bytesPerImage);
            let targetPtr = wasmModule._malloc(bytesPerImage);
            
            if (!sourcePtr || !targetPtr) {
              throw new Error('Failed to allocate memory');
            }

            wasmModule.HEAPU8.set(this.input.data, sourcePtr);
            this.hasAlpha = wasmModule._check_alpha(sourcePtr, numPixels);

            if (this.hasAlpha) {
              this.inputAlpha = new Img(this.img.width, this.img.height);
              wasmModule._copy_alpha_to_rgb(sourcePtr, targetPtr, numPixels);
              this.inputAlpha.data.set(
                wasmModule.HEAPU8.subarray(targetPtr, targetPtr + bytesPerImage)
              );
            }

            wasmModule._free(sourcePtr);
            wasmModule._free(targetPtr);

            // Only update canvas if not in compare mode
            if (!this.compareItem) {
              const canvas = this.$refs.canvas;
              const containerWidth = canvas.width;
              const containerHeight = canvas.height;

              const scaleX = (0.8 * containerWidth) / this.img.width;
              const scaleY = (0.8 * containerHeight) / this.img.height;
              this.imgScale = Math.min(scaleX, scaleY, 4);
              this.imgInitScale = this.imgScale;

              this.imgX = (containerWidth - this.img.width * this.imgScale) / 2;
              this.imgY = (containerHeight - this.img.height * this.imgScale) * 0.4;

              this.drawImage();
            }
            resolve();
          } catch (error) {
            console.error('Error in loadImg:', error);
            if (!this.compareItem) {
              this.cleanup();
            }
            reject(error);
          }
        };

        this.img.onerror = (error) => {
          console.error('Error loading image:', error);
          if (!this.compareItem) {
            this.cleanup();
          }
          reject(new Error('Failed to load image'));
        };
      });
    },
    testdemo(event) {
      const img = event.target;
      this.loadImg(img.src);
    },
    handleDrop(event) {
      if (this.imgLoaded) {
        event.preventDefault();
        return;
      }
      const files = event.dataTransfer.files;
      if (files && files.length > 0) {
        const file = files[0];
        // Get filename without extension
        this.imgName = file.name.replace(/\.[^/.]+$/, "");
        const reader = new FileReader();
        reader.onload = (e) => {
          this.loadImg(e.target.result);
        };
        reader.readAsDataURL(file);
      }
    },
    handleClick() {
      const input = document.createElement("input");
      input.type = "file";
      input.accept = "image/*";
      input.onchange = (e) => {
        const file = e.target.files[0];
        // Get filename without extension
        this.imgName = file.name.replace(/\.[^/.]+$/, "");
        const reader = new FileReader();
        reader.onload = (e) => {
          this.loadImg(e.target.result);
        };
        reader.readAsDataURL(file);
      };
      input.click();
    },
    drawImage() {
      requestAnimationFrame(() => this.drawImage_());
      // this.drawImage_();
    },
    drawImage_() {
      const canvas = this.$refs.canvas;
      const ctx = canvas.getContext("2d", { willReadFrequently: true });
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Use local images for compare view
      if (this.compareItem && this.compareOriginalImg && this.compareUpscaledImg) {
        ctx.drawImage(
          this.compareOriginalImg,
          this.imgX,
          this.imgY,
          this.compareOriginalImg.width * this.imgScale,
          this.compareOriginalImg.height * this.imgScale
        );
        if (this.compareUpscaledImg.src) {
          ctx.drawImage(
            this.compareUpscaledImg,
            ((this.compareUpscaledImg.width / this.compareOriginalImg.width) *
              (this.linePosition - this.imgX)) /
              this.imgScale,
            0,
            this.compareUpscaledImg.width -
              ((this.compareUpscaledImg.width / this.compareOriginalImg.width) *
                (this.linePosition - this.imgX)) /
                this.imgScale,
            this.compareUpscaledImg.height,
            this.linePosition,
            this.imgY,
            this.imgX + this.compareOriginalImg.width * this.imgScale - this.linePosition,
            this.compareOriginalImg.height * this.imgScale
          );
        }
        return;
      }

      // Default: use global images
      ctx.drawImage(
        this.img,
        this.imgX,
        this.imgY,
        this.img.width * this.imgScale,
        this.img.height * this.imgScale
      );

      if (this.processedImg.src) {
        ctx.drawImage(
          this.processedImg,
          ((this.processedImg.width / this.img.width) *
            (this.linePosition - this.imgX)) /
            this.imgScale,
          0,
          this.processedImg.width -
            ((this.processedImg.width / this.img.width) *
              (this.linePosition - this.imgX)) /
              this.imgScale,
          this.processedImg.height,
          this.linePosition,
          this.imgY,
          this.imgX + this.img.width * this.imgScale - this.linePosition,
          this.img.height * this.imgScale
        );
      }
    },
    startDragging(event) {
      if (!this.imgLoaded) return;
      const rect = this.$refs.canvas.getBoundingClientRect();
      const mouseX = event.clientX - rect.left;
      if (Math.abs(mouseX - this.linePosition / this.dpr) < 12) {
        this.startDraggingLine(event);
        return;
      }
      this.dragging = true;
    },
    stopDragging() {
      if (!this.imgLoaded) return;
      if (this.draggingLine) {
        this.stopDraggingLine();
        return;
      }
      this.dragging = false;
    },
    dragImage(event) {
      if (this.dragging) {
        this.imgX += event.movementX * this.dpr;
        this.imgY += event.movementY * this.dpr;
        this.drawImage();
      }
      if (this.draggingLine) {
        this.updateLinePosition(event);
        this.drawImage();
      }
    },
    touchDragImage(event) {
      if (this.touching) {
        const touch = event.touches[0];
        this.imgX += touch.clientX - this.touchStartX;
        this.imgY += touch.clientY - this.touchStartY;
        this.drawImage();
      }
      if (this.draggingLine) {
        this.updateLinePosition(event);
        this.drawImage();
      }
    },
    resizeImage(event) {
      if (!this.imgLoaded) return;
      event.preventDefault();
      const canvas = this.$refs.canvas;
      const rect = canvas.getBoundingClientRect();
      const mouseX = (event.clientX - rect.left) * this.dpr;
      const mouseY = (event.clientY - rect.top) * this.dpr;
      const prevScale = this.imgScale;
      const maxSize = 20 * this.imgInitScale;
      const minSize = 0.05 * this.imgInitScale;
      if (event.deltaY > 0) {
        const newScale = this.imgScale * 0.8;
        this.imgScale = Math.min(Math.max(minSize, newScale), maxSize);
      } else {
        const newScale = this.imgScale * 1.2;
        this.imgScale = Math.min(Math.max(minSize, newScale), maxSize);
      }

      const scaleRatio = this.imgScale / prevScale;
      this.imgX = mouseX - (mouseX - this.imgX) * scaleRatio;
      this.imgY = mouseY - (mouseY - this.imgY) * scaleRatio;

      this.drawImage();
    },
    touchStart(event) {
      this.touching = true;
      this.touchStartImgX = this.imgX;
      this.touchStartImgY = this.imgY;
      if (event.touches.length == 1) {
        if (
          Math.abs(event.touches[0].clientX - this.linePosition / this.dpr) < 12
        ) {
          this.draggingLine = true;
          return;
        }
        this.touchStartX = event.touches[0].clientX * this.dpr;
        this.touchStartY = event.touches[0].clientY * this.dpr;
      } else {
        this.imgScaleStart = this.imgScale;
        const touch1 = event.touches[0];
        const touch2 = event.touches[1];
        this.touchStartDistance =
          Math.sqrt(
            Math.pow(touch2.clientX - touch1.clientX, 2) +
              Math.pow(touch2.clientY - touch1.clientY, 2)
          ) * this.dpr;
        this.touchStartX = ((touch1.clientX + touch2.clientX) / 2) * this.dpr;
        this.touchStartY = ((touch1.clientY + touch2.clientY) / 2) * this.dpr;
      }
    },
    touchMove(event) {
      event.preventDefault();
      if (!this.touching) {
        return;
      }
      if (event.touches.length == 1) {
        const touch = event.touches[0];
        const movementX =
          touch.clientX * this.dpr -
          this.touchStartX +
          this.touchStartImgX -
          this.imgX;
        const movementY =
          touch.clientY * this.dpr -
          this.touchStartY +
          this.touchStartImgY -
          this.imgY;
        if (this.draggingLine) {
          this.updateLinePosition(event.touches[0]);
          this.drawImage();
          return;
        }
        if (this.touching) {
          this.imgX += movementX;
          this.imgY += movementY;
          this.drawImage();
        }
      } else {
        const touch1 = event.touches[0];
        const touch2 = event.touches[1];
        const distance =
          Math.sqrt(
            Math.pow(touch2.clientX - touch1.clientX, 2) +
              Math.pow(touch2.clientY - touch1.clientY, 2)
          ) * this.dpr;
        const canvas = this.$refs.canvas;
        const rect = canvas.getBoundingClientRect();
        const mouseX = this.touchStartX - rect.left;
        const mouseY = this.touchStartY - rect.top;
        const scaleChange = distance / this.touchStartDistance;
        const prevScale = this.imgScale;
        const maxSize = 20 * this.imgInitScale;
        const minSize = 0.05 * this.imgInitScale;
        const newScale = this.imgScaleStart * scaleChange;
        this.imgScale = Math.min(Math.max(minSize, newScale), maxSize);

        const scaleRatio = this.imgScale / prevScale;
        const movementX =
          ((touch1.clientX + touch2.clientX) / 2) * this.dpr - this.touchStartX;
        const movementY =
          ((touch1.clientY + touch2.clientY) / 2) * this.dpr - this.touchStartY;
        this.imgX = mouseX - (mouseX - this.imgX) * scaleRatio + movementX;
        this.imgY = mouseY - (mouseY - this.imgY) * scaleRatio + movementY;
        this.touchStartX = ((touch1.clientX + touch2.clientX) / 2) * this.dpr;
        this.touchStartY = ((touch1.clientY + touch2.clientY) / 2) * this.dpr;
        this.drawImage();
      }
    },
    touchEnd(event) {
      if (event.touches.length == 2) {
        this.touchStartImgX = this.imgX;
        this.touchStartImgY = this.imgY;
        const touch1 = event.touches[0];
        const touch2 = event.touches[1];
        this.touchStartDistance =
          Math.sqrt(
            Math.pow(touch2.clientX - touch1.clientX, 2) +
              Math.pow(touch2.clientY - touch1.clientY, 2)
          ) * this.dpr;
        this.touchStartX = ((touch1.clientX + touch2.clientX) / 2) * this.dpr;
        this.touchStartY = ((touch1.clientY + touch2.clientY) / 2) * this.dpr;
        return;
      }
      if (event.touches.length == 1) {
        this.touchStartImgX = this.imgX;
        this.touchStartImgY = this.imgY;
        this.touchStartX = event.touches[0].clientX * this.dpr;
        this.touchStartY = event.touches[0].clientY * this.dpr;
        return;
      }
      this.touching = false;
      this.draggingLine = false;
      this.touchStartImgX = null;
      this.touchStartImgY = null;
      this.touchStartX = null;
      this.touchStartY = null;
      this.touchStartDistance = null;
    },
    startDraggingLine(event) {
      event.preventDefault();
      if (!this.isDone) return;
      this.draggingLine = true;
    },
    stopDraggingLine() {
      this.draggingLine = false;
    },
    dragLine(event) {
      event.preventDefault();
      if (this.draggingLine) {
        this.updateLinePosition(event);
        this.drawImage();
      }
    },
    updateLinePosition(event) {
      const rect = this.$refs.canvas.getBoundingClientRect();
      this.linePosition = event.clientX * this.dpr - rect.left;
      const line = this.$refs.dragLine;
      line.style.left = Math.floor(this.linePosition / this.dpr) + "px";
    },
    startTask() {
      if (this.input === null) return;
      this.isProcessing = true;
      let worker = this.worker;
      let start = Date.now();
      worker.addEventListener("message", (e) => {
        const { progress, done, output, alertmsg, info } = e.data;
        if (info) {
          this.info = info;
        }
        if (alertmsg) {
          alert(alertmsg);
          this.isProcessing = false;
          worker.terminate();
          return;
        }
        this.progress = progress;
        if (done) {
          if (!this.hasAlpha || (this.hasAlpha && this.inputAlpha)) {
            let factor = this.factor;
            this.output = new Img(
              factor * this.input.width,
              factor * this.input.height,
              new Uint8ClampedArray(output)
            );
          }
          this.info = "Processing Image...";
          if (this.inputAlpha) {
            worker.postMessage(
              {
                input: this.inputAlpha.data.buffer,
                factor: this.factor,
                denoise: this.denoise,
                tile_size: this.tile_size,
                min_lap: this.min_lap,
                model_type: this.model_type,
                width: this.inputAlpha.width,
                height: this.inputAlpha.height,
                model: this.model,
                backend: this.backend,
                hasAlpha: true,
              },
              [this.inputAlpha.data.buffer]
            );
            this.inputAlpha = null;
            return;
          }
          if (this.hasAlpha) {
            let outputArray = new Uint8Array(output);
            let wasmModule = this.wasmModule;
            let sourcePtr = wasmModule._malloc(outputArray.length);
            let targetPtr = wasmModule._malloc(outputArray.length);
            let numPixels = outputArray.length / 4;
            wasmModule.HEAPU8.set(outputArray, sourcePtr);
            wasmModule.HEAPU8.set(this.output.data, targetPtr);
            wasmModule._copy_alpha_channel(sourcePtr, targetPtr, numPixels);
            this.output.data.set(
              wasmModule.HEAPU8.subarray(
                targetPtr,
                targetPtr + outputArray.length
              )
            );
            wasmModule._free(sourcePtr);
            wasmModule._free(targetPtr);
            wasmModule = null;
            this.wasmModule = null;
          }

          const imgCanvas = this.$refs.imgCanvas;
          const imgCtx = imgCanvas.getContext("2d");
          imgCtx.clearRect(0, 0, imgCanvas.width, imgCanvas.height);
          imgCanvas.width = this.output.width;
          imgCanvas.height = this.output.height;
          let outImg = imgCtx.createImageData(
            this.output.width,
            this.output.height
          );
          outImg.data.set(this.output.data);
          this.input = null;
          this.inputAlpha = null;
          this.output = null;
          imgCtx.putImageData(outImg, 0, 0);
          let type = "image/jpeg";
          let quality = 0.92;
          if (this.hasAlpha) type = "image/png";
          imgCanvas.toBlob(
            (blob) => {
              this.processedImg.src = URL.createObjectURL(blob);
            },
            type,
            quality
          );
          this.processedImg.onload = () => {
            if (!this.processedImg.width || !this.processedImg.height) {
              console.error('Processed image failed to load or is invalid.');
              return;
            }
            this.linePosition = this.$refs.canvas.width * 0.5;
            this.$refs.dragLine.style.left = this.linePosition / this.dpr + "px";
            this.drawImage();
            this.info = "Done! Time used: " + (Date.now() - start) / 1000 + "s";
            this.isDone = true;
          };
          this.processedImg.onerror = () => {
            console.error('Processed image failed to load.');
          };
          this.isProcessing = false;
          this.isDone = true;
          worker.terminate();
        }
      });
      worker.postMessage(
        {
          input: this.input.data.buffer,
          factor: this.factor,
          denoise: this.denoise,
          tile_size: this.tile_size,
          min_lap: this.min_lap,
          model_type: this.model_type,
          width: this.input.width,
          height: this.input.height,
          model: this.model,
          backend: this.backend,
          hasAlpha: false,
        },
        [this.input.data.buffer]
      );
    },
    saveImage() {
      const a = document.createElement("a");
      a.href = this.processedImg.src;
      // Get the original filename without extension
      const originalName = this.imgName;
      // Add _upscaled suffix and appropriate extension
      const extension = this.hasAlpha ? '.png' : '.jpg';
      a.download = `${originalName}_upscaled${extension}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    },
    reloadPage() {
      this.worker.terminate();
      this.worker = new Worker(new URL("./worker.js", import.meta.url), {
        type: "module",
      });
      //reset
      const canvas = this.$refs.canvas;
      const ctx = canvas.getContext("2d");
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      this.dragging = false;
      this.touching = false;
      this.imgX = 0;
      this.imgY = 0;
      this.imgScale = 1;
      this.imgInitScale = 1;
      this.linePosition = 0;
      this.drawLine = false;
      this.draggingLine = false;
      this.imgLoaded = false;
      this.dpr = window.devicePixelRatio || 1;
      this.img = new Image();
      this.processedImg = new Image();
      this.hasAlpha = false;
      this.touchStartImgX = null;
      this.touchStartImgY = null;
      this.touchStartX = null;
      this.touchStartY = null;
      this.touchStartDistance = null;
      this.imgScaleStart = 1;

      this.imgLoaded = false;
      this.input = null;
      this.inputAlpha = null;
      this.output = null;
      this.isDragOver = false;
      this.isProcessing = false;
      this.isDone = false;
      this.progress = 0;
      this.model = localStorage.getItem("model") || "anime_plus";
      this.backend = localStorage.getItem("backend") || "webgl";
      this.info = "";
    },
    async handleDrop(e) {
      this.isDragOver = false;
      const files = e.dataTransfer.files;
      if (files.length > 1) {
        // Handle multiple files
        this.addToBatchQueue(Array.from(files));
      } else {
        // Handle single file
        const file = files[0];
        if (file.type.startsWith('image/')) {
          this.loadImg(URL.createObjectURL(file));
        }
      }
    },
    async handleClick() {
      const input = document.createElement('input');
      input.type = 'file';
      input.multiple = true;
      input.accept = 'image/*';
      input.onchange = (e) => {
        const files = e.target.files;
        if (files.length > 1) {
          this.addToBatchQueue(Array.from(files));
        } else {
          const file = files[0];
          this.loadImg(URL.createObjectURL(file));
        }
      };
      input.click();
    },
    async addToBatchQueue(files) {
      const newItems = await Promise.all(files.map(async file => {
        const previewUrl = await this.createPreview(file);
        return {
          file,
          preview: previewUrl, // for backward compatibility
          previewUrl,          // for revocation and display
          status: 'pending',
          result: null,
          error: null,
          progress: 0
        };
      }));
      this.batchQueue.push(...newItems);
    },
    async startBatchProcessing() {
      if (this.isProcessingBatch) return;
      this.isProcessingBatch = true;
      
      // Store initial canvas state if in compare mode
      let initialCanvasState = null;
      let initialCompareState = null;
      
      // Check if we're in compare mode before starting batch processing
      if (this.compareItem) {
        const canvas = this.$refs.canvas;
        const ctx = canvas.getContext('2d');
        initialCanvasState = ctx.getImageData(0, 0, canvas.width, canvas.height);
        
        // Store all compare-related state
        initialCompareState = {
          compareItem: this.compareItem,
          compareOriginalImg: this.compareOriginalImg,
          compareUpscaledImg: this.compareUpscaledImg,
          imgX: this.imgX,
          imgY: this.imgY,
          imgScale: this.imgScale,
          imgInitScale: this.imgInitScale,
          linePosition: this.linePosition,
          imgLoaded: this.imgLoaded,
          isDone: this.isDone,
          dragging: this.dragging,
          touching: this.touching,
          drawLine: this.drawLine,
          draggingLine: this.draggingLine,
          touchStartImgX: this.touchStartImgX,
          touchStartImgY: this.touchStartImgY,
          touchStartX: this.touchStartX,
          touchStartY: this.touchStartY,
          touchStartDistance: this.touchStartDistance,
          imgScaleStart: this.imgScaleStart
        };
      }
      
      try {
        for (const item of this.batchQueue) {
          if (item.status === 'pending') {
            try {
              item.status = 'processing';
              
              // Only reset state if we're not in compare mode
              if (!this.compareItem) {
                this.resetState();
              }
              
              // Load image
              const imgUrl = URL.createObjectURL(item.file);
              await this.loadImg(imgUrl);
              URL.revokeObjectURL(imgUrl);

              // Start upscaling
              await new Promise((resolve, reject) => {
                if (this.input === null) {
                  reject(new Error('Failed to load image'));
                  return;
                }

                this.isProcessing = true;
                let start = Date.now();
                
                this.worker.addEventListener("message", (e) => {
                  const { progress, done, output, alertmsg, info } = e.data;
                  if (info) {
                    this.info = info;
                  }
                  if (alertmsg) {
                    reject(new Error(alertmsg));
                    return;
                  }
                  item.progress = progress;
                  if (done) {
                    if (!this.hasAlpha || (this.hasAlpha && this.inputAlpha)) {
                      let factor = this.factor;
                      this.output = new Img(
                        factor * this.input.width,
                        factor * this.input.height,
                        new Uint8ClampedArray(output)
                      );
                    }
                    this.info = "Processing Image...";
                    if (this.inputAlpha) {
                      this.worker.postMessage(
                        {
                          input: this.inputAlpha.data.buffer,
                          factor: this.factor,
                          denoise: this.denoise,
                          tile_size: this.tile_size,
                          min_lap: this.min_lap,
                          model_type: this.model_type,
                          width: this.inputAlpha.width,
                          height: this.inputAlpha.height,
                          model: this.model,
                          backend: this.backend,
                          hasAlpha: true,
                        },
                        [this.inputAlpha.data.buffer]
                      );
                      this.inputAlpha = null;
                      return;
                    }
                    if (this.hasAlpha) {
                      let outputArray = new Uint8Array(output);
                      let wasmModule = this.wasmModule;
                      let sourcePtr = wasmModule._malloc(outputArray.length);
                      let targetPtr = wasmModule._malloc(outputArray.length);
                      let numPixels = outputArray.length / 4;
                      wasmModule.HEAPU8.set(outputArray, sourcePtr);
                      wasmModule.HEAPU8.set(this.output.data, targetPtr);
                      wasmModule._copy_alpha_channel(sourcePtr, targetPtr, numPixels);
                      this.output.data.set(
                        wasmModule.HEAPU8.subarray(
                          targetPtr,
                          targetPtr + outputArray.length
                        )
                      );
                      wasmModule._free(sourcePtr);
                      wasmModule._free(targetPtr);
                      wasmModule = null;
                      this.wasmModule = null;
                    }

                    const imgCanvas = this.$refs.imgCanvas;
                    const imgCtx = imgCanvas.getContext("2d");
                    imgCtx.clearRect(0, 0, imgCanvas.width, imgCanvas.height);
                    imgCanvas.width = this.output.width;
                    imgCanvas.height = this.output.height;
                    let outImg = imgCtx.createImageData(
                      this.output.width,
                      this.output.height
                    );
                    outImg.data.set(this.output.data);
                    this.input = null;
                    this.inputAlpha = null;
                    this.output = null;
                    imgCtx.putImageData(outImg, 0, 0);
                    let type = "image/jpeg";
                    let quality = 0.92;
                    if (this.hasAlpha) type = "image/png";
                    imgCanvas.toBlob(
                      (blob) => {
                        item.result = blob;
                        item.status = 'done';
                        this.info = "Done! Time used: " + (Date.now() - start) / 1000 + "s";
                        
                        // Create thumbnail of the upscaled result
                        const upscaledImg = new Image();
                        upscaledImg.onload = () => {
                          // Create a canvas for the thumbnail
                          const thumbnailCanvas = document.createElement('canvas');
                          const thumbnailCtx = thumbnailCanvas.getContext('2d');
                          
                          // Set thumbnail size (128x128)
                          const maxSize = 128;
                          let width = upscaledImg.width;
                          let height = upscaledImg.height;
                          
                          // Calculate dimensions while maintaining aspect ratio
                          if (width > height) {
                            if (width > maxSize) {
                              height = Math.round((height * maxSize) / width);
                              width = maxSize;
                            }
                          } else {
                            if (height > maxSize) {
                              width = Math.round((width * maxSize) / height);
                              height = maxSize;
                            }
                          }
                          
                          // Set canvas size and draw the thumbnail
                          thumbnailCanvas.width = width;
                          thumbnailCanvas.height = height;
                          thumbnailCtx.drawImage(upscaledImg, 0, 0, width, height);
                          
                          // Convert to blob and create URL
                          thumbnailCanvas.toBlob(thumbnailBlob => {
                            if (item.previewUrl) {
                              URL.revokeObjectURL(item.previewUrl);
                            }
                            item.previewUrl = URL.createObjectURL(thumbnailBlob);
                            
                            // Only restore compare state if we were actually in compare mode
                            // AND if we're still in the same compare mode
                            if (initialCompareState && this.compareItem === initialCompareState.compareItem) {
                              // Restore all states from initial state
                              Object.assign(this, initialCompareState);
                              
                              // Restore initial canvas state
                              if (initialCanvasState) {
                                const canvas = this.$refs.canvas;
                                const ctx = canvas.getContext('2d');
                                ctx.putImageData(initialCanvasState, 0, 0);
                              }
                              
                              // Update drag line position
                              if (this.$refs.dragLine) {
                                this.$refs.dragLine.style.left = this.linePosition / this.dpr + "px";
                              }
                            }
                            
                            resolve();
                          }, 'image/jpeg', 0.8);
                        };
                        
                        upscaledImg.src = URL.createObjectURL(blob);
                      },
                      type,
                      quality
                    );
                    this.isProcessing = false;
                    this.isDone = true;
                    this.worker.terminate();
                    this.worker = new Worker(new URL("./worker.js", import.meta.url), {
                      type: "module",
                    });
                  }
                });

                this.worker.postMessage(
                  {
                    input: this.input.data.buffer,
                    factor: this.factor,
                    denoise: this.denoise,
                    tile_size: this.tile_size,
                    min_lap: this.min_lap,
                    model_type: this.model_type,
                    width: this.input.width,
                    height: this.input.height,
                    model: this.model,
                    backend: this.backend,
                    hasAlpha: false,
                  },
                  [this.input.data.buffer]
                );
              });

            } catch (error) {
              item.status = 'error';
              item.error = error.message;
            } finally {
              // Only cleanup if we're not in compare mode
              if (!this.compareItem) {
                this.cleanup();
              }
            }
          }
        }
      } finally {
        this.isProcessingBatch = false;
      }
    },
    async downloadSingle(item) {
      if (item.status === 'done' && item.result) {
        const a = document.createElement('a');
        a.href = URL.createObjectURL(item.result);
        a.download = item.file.name.replace(/\.[^/.]+$/, '') + '_upscaled' + (this.hasAlpha ? '.png' : '.jpg');
        a.click();
        URL.revokeObjectURL(a.href);
      } else {
        console.error('No result blob found for this item.');
      }
    },
    async downloadAll() {
      const zip = new JSZip();
      let hasAny = false;
      for (const item of this.batchQueue) {
        if (item.status === 'done' && item.result) {
          zip.file(
            item.file.name.replace(/\.[^/.]+$/, '') + '_upscaled' + (this.hasAlpha ? '.png' : '.jpg'),
            item.result
          );
          hasAny = true;
        } else if (item.status === 'done') {
          console.error('No result blob found for item:', item.file.name);
        }
      }
      if (!hasAny) return;
      const content = await zip.generateAsync({type: 'blob'});
      const url = URL.createObjectURL(content);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'upscaled_images.zip';
      a.click();
      URL.revokeObjectURL(url);
    },
    clearQueue() {
      for (const item of this.batchQueue) {
        if (item.previewUrl) {
          URL.revokeObjectURL(item.previewUrl);
          item.previewUrl = null;
        }
      }
      this.batchQueue = [];
      this.cleanup();
    },
    resetState() {
      // If in compare view, do not reset state
      if (this.compareItem) return;
      
      // Store current states
      const currentImgX = this.imgX;
      const currentImgY = this.imgY;
      const currentImgScale = this.imgScale;
      const currentImgInitScale = this.imgInitScale;
      const currentLinePosition = this.linePosition;
      const currentImgLoaded = this.imgLoaded;
      const currentIsDone = this.isDone;
      const currentDragging = this.dragging;
      const currentTouching = this.touching;
      const currentDrawLine = this.drawLine;
      const currentDraggingLine = this.draggingLine;
      const currentTouchStartImgX = this.touchStartImgX;
      const currentTouchStartImgY = this.touchStartImgY;
      const currentTouchStartX = this.touchStartX;
      const currentTouchStartY = this.touchStartY;
      const currentTouchStartDistance = this.touchStartDistance;
      const currentImgScaleStart = this.imgScaleStart;

      // Reset all states
      this.dragging = false;
      this.touching = false;
      this.imgX = 0;
      this.imgY = 0;
      this.imgScale = 1;
      this.imgInitScale = 1;
      this.linePosition = 0;
      this.drawLine = false;
      this.draggingLine = false;
      this.imgLoaded = false;
      this.dpr = window.devicePixelRatio || 1;
      this.img = new Image();
      this.processedImg = new Image();
      this.hasAlpha = false;
      this.touchStartImgX = null;
      this.touchStartImgY = null;
      this.touchStartX = null;
      this.touchStartY = null;
      this.touchStartDistance = null;
      this.imgScaleStart = 1;
      this.input = null;
      this.inputAlpha = null;
      this.output = null;
      this.isDragOver = false;
      this.isProcessing = false;
      this.isDone = false;
      this.progress = 0;

      // If we were in compare mode, restore those states
      if (this.compareItem) {
        this.imgX = currentImgX;
        this.imgY = currentImgY;
        this.imgScale = currentImgScale;
        this.imgInitScale = currentImgInitScale;
        this.linePosition = currentLinePosition;
        this.imgLoaded = currentImgLoaded;
        this.isDone = currentIsDone;
        this.dragging = currentDragging;
        this.touching = currentTouching;
        this.drawLine = currentDrawLine;
        this.draggingLine = currentDraggingLine;
        this.touchStartImgX = currentTouchStartImgX;
        this.touchStartImgY = currentTouchStartImgY;
        this.touchStartX = currentTouchStartX;
        this.touchStartY = currentTouchStartY;
        this.touchStartDistance = currentTouchStartDistance;
        this.imgScaleStart = currentImgScaleStart;
      }
    },
    cleanup() {
      // If in compare view, do not cleanup
      if (this.compareItem) return;

      // Store current states
      const currentImgX = this.imgX;
      const currentImgY = this.imgY;
      const currentImgScale = this.imgScale;
      const currentImgInitScale = this.imgInitScale;
      const currentLinePosition = this.linePosition;
      const currentImgLoaded = this.imgLoaded;
      const currentIsDone = this.isDone;
      const currentDragging = this.dragging;
      const currentTouching = this.touching;
      const currentDrawLine = this.drawLine;
      const currentDraggingLine = this.draggingLine;
      const currentTouchStartImgX = this.touchStartImgX;
      const currentTouchStartImgY = this.touchStartImgY;
      const currentTouchStartX = this.touchStartX;
      const currentTouchStartY = this.touchStartY;
      const currentTouchStartDistance = this.touchStartDistance;
      const currentImgScaleStart = this.imgScaleStart;

      // Clear canvas
      const canvas = this.$refs.canvas;
      const ctx = canvas.getContext('2d', { willReadFrequently: true });
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      // Clear image canvas
      const imgCanvas = this.$refs.imgCanvas;
      const imgCtx = imgCanvas.getContext('2d', { willReadFrequently: true });
      imgCtx.clearRect(0, 0, imgCanvas.width, imgCanvas.height);
      
      // Reset state
      this.imgLoaded = false;
      this.input = null;
      this.inputAlpha = null;
      this.output = null;
      this.isProcessing = false;
      this.isDone = false;
      this.progress = 0;
      
      // Clear image objects
      this.img = new Image();
      this.processedImg = new Image();
      
      // Clear URLs
      if (this.processedImg.src) {
        URL.revokeObjectURL(this.processedImg.src);
      }
      
      // If we were in compare mode, restore those states
      if (this.compareItem) {
        this.imgX = currentImgX;
        this.imgY = currentImgY;
        this.imgScale = currentImgScale;
        this.imgInitScale = currentImgInitScale;
        this.linePosition = currentLinePosition;
        this.imgLoaded = currentImgLoaded;
        this.isDone = currentIsDone;
        this.dragging = currentDragging;
        this.touching = currentTouching;
        this.drawLine = currentDrawLine;
        this.draggingLine = currentDraggingLine;
        this.touchStartImgX = currentTouchStartImgX;
        this.touchStartImgY = currentTouchStartImgY;
        this.touchStartX = currentTouchStartX;
        this.touchStartY = currentTouchStartY;
        this.touchStartDistance = currentTouchStartDistance;
        this.imgScaleStart = currentImgScaleStart;
      }
    },
    retryItem(item) {
      item.status = 'pending';
      item.error = null;
      this.startBatchProcessing();
    },
    async createPreview(file) {
      return new Promise((resolve, reject) => {
        // Validate file size (e.g., max 50MB)
        const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB
        if (file.size > MAX_FILE_SIZE) {
          reject(new Error('File too large. Maximum size is 50MB.'));
          return;
        }

        // Validate file type
        if (!file.type.startsWith('image/')) {
          reject(new Error('Invalid file type. Please upload an image.'));
          return;
        }

        const img = new Image();
        img.onload = () => {
          try {
            // Create a canvas for the thumbnail
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            
            // Set thumbnail size (128x128)
            const maxSize = 128;
            let width = img.width;
            let height = img.height;
            
            // Calculate dimensions while maintaining aspect ratio
            if (width > height) {
              if (width > maxSize) {
                height = Math.round((height * maxSize) / width);
                width = maxSize;
              }
            } else {
              if (height > maxSize) {
                width = Math.round((width * maxSize) / height);
                height = maxSize;
              }
            }
            
            // Set canvas size and draw the thumbnail
            canvas.width = width;
            canvas.height = height;
            ctx.drawImage(img, 0, 0, width, height);
            
            // Convert to blob and create URL
            canvas.toBlob(blob => {
              if (!blob) {
                reject(new Error('Failed to create thumbnail blob'));
                return;
              }
              try {
                const url = URL.createObjectURL(blob);
                resolve(url);
              } catch (error) {
                reject(new Error('Failed to create object URL: ' + error.message));
              }
            }, 'image/jpeg', 0.8); // Use JPEG for better compression
          } catch (error) {
            reject(new Error('Failed to create thumbnail: ' + error.message));
          } finally {
            // Clean up the image URL
            if (img.src.startsWith('blob:')) {
              URL.revokeObjectURL(img.src);
            }
          }
        };
        
        img.onerror = () => {
          reject(new Error('Failed to load image for preview'));
        };
        
        try {
          const fileUrl = URL.createObjectURL(file);
          img.src = fileUrl;
        } catch (error) {
          reject(new Error('Failed to create file URL: ' + error.message));
        }
      });
    },
    async compareBatchItem(item) {
      // Clean up previous URLs if any
      if (this.compareOriginalImg && this.compareOriginalImg.src) {
        URL.revokeObjectURL(this.compareOriginalImg.src);
      }
      if (this.compareUpscaledImg && this.compareUpscaledImg.src) {
        URL.revokeObjectURL(this.compareUpscaledImg.src);
      }
      // Load original image
      const fileUrl = URL.createObjectURL(item.file);
      const originalImg = new Image();
      await new Promise((resolve) => {
        originalImg.onload = resolve;
        originalImg.src = fileUrl;
      });
      // Clone the upscaled Blob and create a new URL
      const upscaledBlob = item.result.slice(0, item.result.size, item.result.type);
      const upscaledUrl = URL.createObjectURL(upscaledBlob);
      const upscaledImg = new Image();
      await new Promise((resolve) => {
        upscaledImg.onload = resolve;
        upscaledImg.src = upscaledUrl;
      });
      // Set up state for compare view
      this.compareItem = item;
      this.compareOriginalImg = originalImg;
      this.compareUpscaledImg = upscaledImg;
      this.imgLoaded = true;
      this.isDone = true;
      // Center and fit image, enable zoom/pan
      this.$nextTick(() => {
        // Canvas and container
        const container = this.$refs.canvasContainer;
        const canvas = this.$refs.canvas;
        // Set canvas size
        canvas.width = container.offsetWidth * this.dpr;
        canvas.height = container.offsetHeight * this.dpr;
        canvas.style.width = `${container.offsetWidth}px`;
        canvas.style.height = `${container.offsetHeight}px`;
        // Calculate scale to fit
        const scaleX = (0.8 * canvas.width) / originalImg.width;
        const scaleY = (0.8 * canvas.height) / originalImg.height;
        this.imgScale = Math.min(scaleX, scaleY, 4);
        this.imgInitScale = this.imgScale;
        // Center image
        this.imgX = (canvas.width - originalImg.width * this.imgScale) / 2;
        this.imgY = (canvas.height - originalImg.height * this.imgScale) * 0.4;
        // Set slider position
        this.linePosition = canvas.width * 0.5;
        if (this.$refs.dragLine) {
          this.$refs.dragLine.style.left = this.linePosition / this.dpr + "px";
        }
        this.drawImage();

        // Capture the initial state for batch processing
        console.log('[Compare] Capturing initial state for:', item.file.name);
        const ctx = canvas.getContext('2d');
        this.batchCompareState = {
          canvasState: ctx.getImageData(0, 0, canvas.width, canvas.height),
          compareState: {
            compareItem: this.compareItem,
            compareOriginalImg: this.compareOriginalImg,
            compareUpscaledImg: this.compareUpscaledImg,
            imgX: this.imgX,
            imgY: this.imgY,
            imgScale: this.imgScale,
            imgInitScale: this.imgInitScale,
            linePosition: this.linePosition,
            imgLoaded: this.imgLoaded,
            isDone: this.isDone,
            dragging: this.dragging,
            touching: this.touching,
            drawLine: this.drawLine,
            draggingLine: this.draggingLine,
            touchStartImgX: this.touchStartImgX,
            touchStartImgY: this.touchStartImgY,
            touchStartX: this.touchStartX,
            touchStartY: this.touchStartY,
            touchStartDistance: this.touchStartDistance,
            imgScaleStart: this.imgScaleStart
          }
        };
        console.log('[Compare] Initial state captured:', {
          canvasWidth: canvas.width,
          canvasHeight: canvas.height,
          imgX: this.batchCompareState.compareState.imgX,
          imgY: this.batchCompareState.compareState.imgY,
          imgScale: this.batchCompareState.compareState.imgScale,
          linePosition: this.batchCompareState.compareState.linePosition
        });
      });
    },
    async waitForCompareExit() {
      if (!this.compareItem) return;
      await new Promise(resolve => {
        const check = () => {
          if (!this.compareItem) {
            this.$off('compare-exit', check);
            resolve();
          }
        };
        this.$on('compare-exit', check);
      });
    },
  },
};
</script>

<style>
html, body, #app {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
}

/* Add styles for batch processing UI */
.batch-controls {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.8);
  padding: 15px;
  border-radius: 8px;
  color: white;
  max-width: 80%;
  max-height: 300px;
  overflow-y: auto;
}

.batch-queue {
  margin-bottom: 10px;
}

.queue-item {
  display: flex;
  align-items: center;
  margin: 5px 0;
  padding: 5px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
}

.queue-item .filename {
  flex: 1;
  margin-right: 10px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.queue-item .status {
  margin: 0 10px;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 0.9em;
}

.queue-item .status.pending {
  background: #666;
}

.queue-item .status.processing {
  background: #2196F3;
}

.queue-item .status.done {
  background: #4CAF50;
}

.queue-item .status.error {
  background: #f44336;
}

.batch-actions {
  display: flex;
  gap: 10px;
  justify-content: center;
}

.batch-actions button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  background: #2196F3;
  color: white;
  cursor: pointer;
}

.batch-actions button:disabled {
  background: #666;
  cursor: not-allowed;
}

.batch-actions button:hover:not(:disabled) {
  background: #1976D2;
}

.batch-options {
  background: rgba(0, 0, 0, 0.9);
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 20px;
  color: white;
}

.batch-options .opt {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 15px;
}

.batch-options .description {
  display: block;
  margin-bottom: 5px;
  color: #ccc;
}

.batch-options select {
  width: 100%;
  padding: 8px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.batch-options select:focus {
  outline: none;
  border-color: #2196F3;
}

.batch-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.batch-stats {
  display: flex;
  gap: 10px;
}

.batch-item {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  align-items: stretch;
  background: rgba(0, 0, 0, 0.8);
  border-radius: 12px;
  overflow: hidden;
  min-height: 220px;
  aspect-ratio: 1/1;
  padding: 0;
}

.image-container {
  position: relative;
  aspect-ratio: 1;
  overflow: hidden;
}

.preview-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: blur(3px);
  transform: scale(1.1); /* Prevent blur edges from showing */
}

.status-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.3s ease;
  z-index: 3;
}

.status-overlay.processing {
  background: rgba(33, 150, 243, 0.7);
}

.status-overlay.done {
  background: rgba(76, 175, 80, 0.7);
}

.status-overlay.error {
  background: rgba(244, 67, 54, 0.7);
}

.status-overlay.pending {
  background: rgba(158, 158, 158, 0.7);
}

.status-content {
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 16px;
}

.status-text {
  text-transform: capitalize;
  margin-top: 5px;
  color: white;
  font-size: 1.2em;
  font-weight: 500;
}

.status-actions {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.action-button.small {
  padding: 8px 16px;
  font-size: 0.9em;
  min-width: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}

.action-button.small.download-overlay-btn {
  background: #fff;
  color: #222;
  font-weight: 500;
  border-radius: 6px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  transition: all 0.2s ease;
}

.action-button.small.download-overlay-btn:hover {
  background: #e0e0e0;
  transform: translateY(-1px);
}

.action-button.small.compare-btn {
  background: #2196F3;
  color: white;
  border: none;
  border-radius: 6px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  transition: all 0.2s ease;
}

.action-button.small.compare-btn:hover {
  background: #1976D2;
  transform: translateY(-1px);
}

.action-button.small.compare-btn:disabled {
  background: #666;
  cursor: not-allowed;
  transform: none;
}

.progress-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.progress-text {
  font-size: 2.5em;
  font-weight: bold;
  color: white;
  text-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.error-message {
  color: #f44336;
}

.download-button,
.retry-button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  background: #2196F3;
  color: white;
  cursor: pointer;
}

.download-button:hover,
.retry-button:hover {
  background: #1976D2;
}

.batch-start {
  margin-top: 20px;
  text-align: center;
}

.start-button {
  padding: 12px 24px;
  font-size: 1.1em;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background 0.3s;
}

.start-button:hover:not(:disabled) {
  background: #388E3C;
}

.start-button:disabled {
  background: #666;
  cursor: not-allowed;
}

.batch-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.batch-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  background: rgba(0, 0, 0, 0.8);
  padding: 20px;
  border-radius: 12px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 24px;
}

.header-left h2 {
  margin: 0;
  font-size: 1.5em;
  color: white;
}

.batch-stats {
  display: flex;
  gap: 16px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 16px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
}

.stat-value {
  font-size: 1.2em;
  font-weight: bold;
  color: white;
}

.stat-label {
  font-size: 0.8em;
  color: rgba(255, 255, 255, 0.7);
}

.header-actions {
  display: flex;
  gap: 12px;
}

.action-button {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border: none;
  border-radius: 6px;
  font-size: 0.9em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.action-button.primary {
  background: #4CAF50;
  color: white;
}

.action-button.secondary {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.action-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.action-button:not(:disabled):hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.batch-options {
  background: rgba(0, 0, 0, 0.8);
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 24px;
}

.options-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.options-header h3 {
  margin: 0;
  color: white;
  font-size: 1.2em;
}

.options-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.option-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.option-group label {
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.9em;
}

.styled-select {
  padding: 8px 12px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.styled-select:focus {
  outline: none;
  border-color: #4CAF50;
}

.start-button {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 1em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.start-button:disabled {
  background: #666;
  cursor: not-allowed;
}

.start-button:not(:disabled):hover {
  background: #388E3C;
  transform: translateY(-1px);
}

.batch-grid {
  max-height: 60vh;
  overflow-y: auto;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
}

.batch-item {
  background: rgba(0, 0, 0, 0.8);
  border-radius: 12px;
  overflow: hidden;
  transition: transform 0.3s ease;
}

.batch-item:hover {
  transform: translateY(-2px);
}

.item-info {
  padding: 0px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.filename {
  color: white;
  font-size: 0.9em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-actions {
  display: flex;
  gap: 8px;
}

.hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 60vh;
  padding-top: 60px;
}
.hero-title {
  font-size: 2.5em;
  font-weight: 800;
  color: #4caf50;
  margin-bottom: 10px;
  text-align: center;
}
.hero-subtitle {
  font-size: 1.2em;
  color: #333;
  margin-bottom: 32px;
  text-align: center;
}
.upload-button {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background-color: #ff568a;
  border: none;
  border-radius: 50%;
  width: 120px;
  height: 120px;
  margin-bottom: 24px;
  transition: background 0.3s;
}
.upload-button:hover {
  background-color: #d21d5a;
}
.upload-container {
  width: 48px;
  height: 48px;
}
.upload-text {
  margin-top: 12px;
  color: #fff;
  font-size: 1em;
  font-weight: 500;
}
.demo-section {
  margin-top: 32px;
  text-align: center;
}
.demo-title {
  color: #888;
  font-size: 1em;
  margin-bottom: 8px;
}
.demo-images {
  display: flex;
  gap: 16px;
  justify-content: center;
}
.demoimg {
  width: 64px;
  height: 64px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}
.demoimg:hover {
  transform: scale(1.08);
  box-shadow: 0 4px 16px rgba(76,175,80,0.15);
}
@media (max-width: 700px) {
  .hero {
    min-height: 30vh;
    padding-top: 16px;
    padding-bottom: 16px;
  }
  .hero-title {
    font-size: 1.1em;
    margin-bottom: 6px;
  }
  .hero-subtitle {
    font-size: 0.95em;
    margin-bottom: 12px;
    padding: 0 8px;
  }
  .upload-button {
    width: 64px;
    height: 64px;
    margin-bottom: 12px;
  }
  .upload-container {
    width: 24px;
    height: 24px;
  }
  .upload-text {
    font-size: 0.85em;
    margin-top: 8px;
  }
  .demo-section {
    margin-top: 12px;
  }
  .demo-title {
    font-size: 0.9em;
    margin-bottom: 4px;
  }
  .demoimg {
    width: 32px;
    height: 32px;
    border-radius: 6px;
  }
  .batch-header, .batch-options {
    flex-direction: column;
    align-items: stretch;
    padding: 6px;
    margin-bottom: 8px;
  }
  .batch-header h2 {
    font-size: 1em;
    margin-bottom: 4px;
  }
  .batch-stats {
    gap: 4px;
    font-size: 0.85em;
  }
  .batch-actions {
    flex-direction: column;
    gap: 6px;
    margin-top: 6px;
  }
  .batch-options .options-header {
    flex-direction: column;
    gap: 6px;
    margin-bottom: 8px;
  }
  .options-grid {
    grid-template-columns: 1fr;
    gap: 8px;
  }
  .option-group label {
    font-size: 0.85em;
  }
  .styled-select {
    font-size: 0.9em;
    padding: 6px 8px;
  }
  .start-button {
    padding: 8px 12px;
    font-size: 0.95em;
  }
  .batch-grid {
    grid-template-columns: 1fr;
    gap: 8px;
  }
  .batch-item {
    border-radius: 6px;
    margin-bottom: 4px;
  }
  .image-container {
    aspect-ratio: 1;
    min-width: 0;
    min-height: 0;
    max-width: 100%;
  }
  .item-info {
    padding: 6px;
    gap: 2px;
  }
  .filename {
    font-size: 0.75em;
    word-break: break-all;
  }
  .item-actions {
    gap: 4px;
  }
  .action-button, .action-button.small {
    padding: 5px 8px;
    font-size: 0.75em;
  }
  .progress-ring {
    width: 24px;
    height: 24px;
  }
  .status-content {
    font-size: 0.8em;
  }
  .floating-menu {
    width: 95vw;
    min-width: 0;
    max-width: 98vw;
    left: 2.5vw;
    padding: 10px;
  }
  .goback, .github {
    width: 32px;
    height: 32px;
    top: 6px;
    left: 6px;
    right: 6px;
  }
  .dragLine {
    width: 6px;
  }
}

/* Add this to the style section */
.image-dark-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.25);
  z-index: 2;
  pointer-events: none;
  border-radius: inherit;
}

/* Add to style section */
.download-overlay-btn {
  margin-top: 8px;
  background: #fff;
  color: #222;
  font-weight: 500;
  border-radius: 6px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  transition: background 0.2s;
}
.download-overlay-btn:hover {
  background: #e0e0e0;
}

.compare-btn {
  background: #2196F3;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 6px 12px;
  cursor: pointer;
  transition: background 0.3s;
}

.compare-btn:hover {
  background: #1976D2;
}

.compare-btn:disabled {
  background: #666;
  cursor: not-allowed;
}
</style>