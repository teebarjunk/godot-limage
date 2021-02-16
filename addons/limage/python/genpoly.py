# NOT READY

# DONT USE

import numpy as np
import cv2 as cv

EXTRA_BORDER = 2
SIMPLIFY = 0.003

def get_points(path:str, local_path:str) -> list:
	im = cv.imread(path)
	imgray = cv.cvtColor(im, cv.COLOR_BGR2GRAY)
	
	# cv.imwrite('./test_result2.png', imgray)
	
	ret, thresh = cv.threshold(imgray, 127, 255, 0)
	contours, hierarchy = cv.findContours(thresh, cv.RETR_TREE, cv.CHAIN_APPROX_SIMPLE)
	cv.drawContours(imgray, contours, -1, (255,255,255), EXTRA_BORDER)

	# , cv.RETR_TREE   cv.RETR_EXTERNAL
	ret, thresh = cv.threshold(imgray, 127, 255, 0)
	contours, hierarchy = cv.findContours(thresh, cv.RETR_TREE, cv.CHAIN_APPROX_SIMPLE)
	
	if len(contours) == 0:
		print("no contours ", path)
		return None
	
	epsilon = SIMPLIFY * cv.arcLength(contours[0], True)
	approx = cv.approxPolyDP(contours[0], epsilon, True)
	cv.drawContours(im, [approx], -1, (0,255,0), 1)

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