#!/bin/bash
# Copy ONNX model files to app bundle

echo "Copying ONNX model files..."

MODELS_DIR="${SRCROOT}/Phi3Assistant"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"

if [ -f "${MODELS_DIR}/Phi-3-mini-4k-instruct-q4.onnx" ]; then
    cp "${MODELS_DIR}/Phi-3-mini-4k-instruct-q4.onnx" "${DEST_DIR}/"
    echo "✅ Copied Phi-3-mini-4k-instruct-q4.onnx"
else
    echo "❌ Model file not found: ${MODELS_DIR}/Phi-3-mini-4k-instruct-q4.onnx"
fi

if [ -f "${MODELS_DIR}/Phi-3-mini-4k-instruct-q4.onnx.data" ]; then
    cp "${MODELS_DIR}/Phi-3-mini-4k-instruct-q4.onnx.data" "${DEST_DIR}/"
    echo "✅ Copied Phi-3-mini-4k-instruct-q4.onnx.data"
else
    echo "❌ Model data file not found: ${MODELS_DIR}/Phi-3-mini-4k-instruct-q4.onnx.data"
fi

echo "Model copy complete!"
