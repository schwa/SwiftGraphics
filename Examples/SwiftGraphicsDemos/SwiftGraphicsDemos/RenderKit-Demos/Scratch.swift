//
//  Scratch.swift
//  Demos
//
//  Created by Jonathan Wight on 9/17/23.
//

import Foundation
import Metal


//Description:    CT study of a cadaver head
//Dimensions:    113 slices of 256 x 256 pixels,
//        voxel grid is rectangular, and
//        X:Y:Z shape of each voxel is 1:1:2
//Files:        113 binary files, one file per slice
//File format:    16-bit integers (Mac byte ordering), file contains no header
//Data source:    acquired on a General Electric CT Scanner and provided
//                courtesy of North Carolina Memorial Hospital
