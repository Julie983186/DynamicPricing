from paddleocr import PaddleOCR
import os

ocr = PaddleOCR(lang='ch', use_textline_orientation=False)

# PaddleOCR 4.x 版本查模型目錄
det_model_dir = ocr.det_model_dir if hasattr(ocr, 'det_model_dir') else ocr._det_model_dir
rec_model_dir = ocr.rec_model_dir if hasattr(ocr, 'rec_model_dir') else ocr._rec_model_dir
cls_model_dir = ocr.cls_model_dir if hasattr(ocr, 'cls_model_dir') else (ocr._cls_model_dir if hasattr(ocr, '_cls_model_dir') else None)

print("檢測模型:", det_model_dir)
print("識別模型:", rec_model_dir)
print("方向分類模型:", cls_model_dir)

# 列出檔案
if det_model_dir and os.path.exists(det_model_dir):
    print("檢測模型檔案:", os.listdir(det_model_dir))
if rec_model_dir and os.path.exists(rec_model_dir):
    print("識別模型檔案:", os.listdir(rec_model_dir))
if cls_model_dir and os.path.exists(cls_model_dir):
    print("方向分類模型檔案:", os.listdir(cls_model_dir))
