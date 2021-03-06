{{
┌─────────────────────────────────────────────────┐
│ Parallax Laser Range Finder                     │
│ Global Constants                                │
│                                                 │
│ Author: Joe Grand                               │                     
│ Copyright (c) 2011 Grand Idea Studio, Inc.      │
│ Web: http://www.grandideastudio.com             │
│ Technical Support: support@parallax.com         │ 
│                                                 │
│ Distributed under a Creative Commons            │
│ Attribution 3.0 United States license           │
│ http://creativecommons.org/licenses/by/3.0/us/  │
└─────────────────────────────────────────────────┘

Program Description:

This object provides global constants used for the
OVM7690-based Parallax Laser Range Finder. 
 
}}


CON
  MAGIC         = $4C524647    ' "LRFG" (Magic number used in SystemInit to check if EEPROM has been programmed with parameters)
  
  ' Actual OVM7690 resolution (set in OVM7690_obj setRes object)
  ' Must be <= 640 x 480
  RES_FULL_X    = 176    ' QCIF                          
  RES_FULL_Y    = 144

  RES_ROI_X     = 640    ' VGA  
  RES_ROI_Y     = 480
  RES_ROI_X_CENTER   = RES_ROI_X / 2  ' Center of frame

  ' Frame buffer resolution
  ' 8 bits/pixel grayscale, only using the Y/luma component
  ' Full frame
  FB_FULL_X     = 160          ' Must be <= to RES_FULL_X                        
  FB_FULL_Y     = 128          ' Must be <= to RES_FULL_Y
  FB_SIZE       = (FB_FULL_X * FB_FULL_Y) / 4    ' Size of frame buffer (in longs)                              

  ' ROI single and processed frames                                                          
  FB_ROI_X      = 320           ' Must be <= to RES_ROI_X                              
  FB_ROI_Y      = 16            ' Must be <= to RES_ROI_Y
  FB_ROI_SIZE   = (FB_ROI_X * FB_ROI_Y) / 4       ' Size of frame buffer (in longs)

  ' For identifying Region of Interest within the frame
  ROI_Y         = (((RES_ROI_Y - FB_ROI_Y) / 2) - 6 ) ' Starting location (we want to capture near the center portion of the frame where the laser diode is pointing, not the top of the frame)          
  ROI_X         = FB_ROI_X
      
  ' Blob detection
  ' Tracking parameters, pixel must be above a minimum brightness and below maximum brightness in order to be considered as "valid"
  ' OVM7690 returns Y/luma (brightness) as [0 = darkest, 255 = brightest]
  LOWER_BOUND   = 50            ' Minimum value (50/255 = 20%)
  UPPER_BOUND   = 255           ' Maximum value (255/255 = 100%)

  SUM_THRESHOLD = 3             ' Threshold that column sum must be above in order to be considered part of the blob
  MAX_BLOBS     = 6             ' Maximum number of blobs to detect within the frame
  BLOB_MASS_THRESHOLD = 16      ' Minimum blob mass to accept

  ' Locations within blob array
  BLOB_LEFT     = 0             ' X coordinate of left side (beginning) of detected blob
  BLOB_RIGHT    = 1             ' X coordinate of right side (end) of detected blob
  BLOB_MASS     = 2             ' Mass of blob (sum of all valid pixels within the blob)
  BLOB_CENTROID = 3             ' Centroid (center of mass) of blob
                                
  ' Range finding
  LRF_H_CM        = 7.8               ' Distance between centerpoints of camera and laser, fixed based on PCB layout (cm)
  ANGLE_MIN       = 0.030699015       ' Minimum allowable angle (radians) = arctan(h/D) (corresponds to D = 2540 mm, anything longer will be too unreliable)

  ' Calibration
  CAL_MIN_DISTANCE      = 20        ' Minimum calibration distance (cm)
  CAL_MAX_DISTANCE      = 70        ' Maximum calibration distance (cm)
  CAL_STEP              = 10        ' Step size (cm)
  CAL_NUM_PER_DISTANCE  = 4         ' Number of measurements per distance

  
PUB PinDefsOnlySoIgnoreThis
  return 0