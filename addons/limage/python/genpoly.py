# NOT READY

# DONT USE

import numpy as np
import cv2 as cv

EXTRA_BORDER = 4
SIMPLIFY = 0.003

def get_points(pil_image, local_path) -> str:#path, local_path:str) -> list:
	# im = cv.imread(path)
	im = cv.cvtColor(np.array(pil_image), cv.COLOR_RGBA2BGRA)
	# cv.imwrite('./test_result0.png', im)
	
	_, mask = cv.threshold(im[:, :, 3], 0, 255, cv.THRESH_BINARY)
	
	# imgray = cv.cvtColor(im, cv.COLOR_BGRA2GRAY)
	
	# cv.imwrite('./test_result1.png', im)
	# cv.imwrite('./test_result2.png', imgray)
	
	# cv.imwrite('./test_result1.png', mask)
	
	_, thresh = cv.threshold(mask, 127, 255, cv.THRESH_BINARY)
	contours, hierarchy = cv.findContours(mask, cv.RETR_TREE, cv.CHAIN_APPROX_SIMPLE)
	cv.drawContours(im, contours, -1, (0,0,0,255), EXTRA_BORDER)

	# cv.imwrite('./test_result2.png', im)
	
	_, mask = cv.threshold(im[:, :, 3], 0, 255, cv.THRESH_BINARY)
	
	# , cv.RETR_TREE   cv.RETR_EXTERNAL
	_, thresh = cv.threshold(mask, 127, 255, cv.THRESH_BINARY)
	contours, hierarchy = cv.findContours(thresh, cv.RETR_TREE, cv.CHAIN_APPROX_SIMPLE)
	
	if len(contours) == 0:
		print("no contours ", local_path)
		return None
	
	epsilon = SIMPLIFY * cv.arcLength(contours[0], True)
	approx = cv.approxPolyDP(contours[0], epsilon, True)
	cv.drawContours(im, [approx], -1, (0,255,0,255), 2)
	
	# cv.imwrite('./test_result3.png', im)
	
	points = ""
	uvs = ""
	for i in range(len(approx)):
		if i != 0:
			points += ", "
		x = approx[i][0][0]
		y = approx[i][0][1]
		points += f"{x}, {y}"
		uvs += f"{x}, {y}"
	
	return f"""[gd_scene load_steps=2 format=2]

[ext_resource path="{local_path}" type="Texture" id=1]

[node name="Polygon2D" type="Polygon2D"]
texture = ExtResource( 1 )
polygon = PoolVector2Array( {points} )
uv = PoolVector2Array( {uvs} )
"""
	
	# print(points)
	# print(len(contours[0]), len(approx))
	# cv.imwrite('./test_result.png', im)
	# cv.imshow('image',im)