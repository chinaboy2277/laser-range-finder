{{
┌─────────────────────────────────────────────────┐
│ OmniVision OVM7690 CameraCube Module            │
│ Frame Grabber Cog                               │
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

This cog retrieves the current frame from the
Omnivision OVM7690 CMOS CameraCube module and
stores it in the frame buffer (located in hub RAM).

It also sets a flag to a non-zero state so the
calling object knows when the frame grab is done.
 
}}


CON

  
VAR
  long Cog                      ' Used to store ID of newly started cog
  
  
OBJ
  g             : "LRF_con"                         ' Laser Range Finder global constants 
  'dbg           : "PASDebug"                        '<---- Add for Propeller Assembly Sourcecode Debugger (PASD), http://propeller.wikispaces.com/PASD and http://www.insonix.ch/propeller/prop_pasd.html


PUB start(fb) : addr
  ' Start a new cog to run PASM routine starting at @entry
  ' Returns the address of the frame buffer (in main/hub memory) if a cog was successfully started, or 0 if error.
  stop                                     ' Call the Stop function, just in case the calling object called Start two times in a row.
  Cog := cognew(@entry, fb) + 1            ' Launch the cog with a pointer to the parameters
  if Cog
    addr := fb 
    
  'dbg.start(31,30,@entry)                 '<---- Add for Debugger
  

PUB stop
  ' Stop the cog we started earlier, if any
  if Cog
    cogstop(Cog~ - 1)


DAT
                        org     0
entry

'  --------- Debugger Kernel add this at Entry (Addr 0) ---------
   'long $34FC1202,$6CE81201,$83C120B,$8BC0E0A,$E87C0E03,$8BC0E0A
   'long $EC7C0E05,$A0BC1207,$5C7C0003,$5C7C0003,$7FFC,$7FF8
'  -------------------------------------------------------------- 

' Propeller @ 96MHz (overclocked, 6MHz XTAL)     = 0.01042uS/cycle

' Timing partially defined in Section 6.1, OV7690 CSP3 Data Sheet rev. 2.11

' 640x480 (VGA) @ 5fps (4MHz PCLK)
' ------------------------------------                       @96MHz
' VSYNC width                                   = 1.565mS  = 75095 cycles
' Time from VSYNC low to HREF high              = 7.865mS  = 754798 cycles
' Time in between lines/HREF                    = 70uS     = 6717 cycles
' Time from last HREF in frame to next VSYNC    = 3.11mS   = 298464 cycles
' Pixel clock (PCLK)                            = 0.250uS  = 24 cycles/bit
'                                                            (must grab data within 12 cycles of PCLK going high)
' Read every pixel (16 bits each)
' PCLK is asserted (HIGH) when there is valid pixel data on the bus
' 8 bits (D7..D0) are transferred at a time, so two PCLKs are needed for each 16-bit pixel
'
'       Timing diagram @ 96MHz Propeller
'              24 cycles/bit
'       Data valid when PCLK is HIGH
'
'           Y      U/V      Y  ...
'         
'                     
'       t=0   12  24  36  48
'      cycles

init                    mov     dira, PINS              ' Configure I/O pins

                        mov     fbAddr, par             ' Copy PAR ($1F0) to fbAddr
                        mov     fbAddr2, fbAddr
                        add     fbAddr2, #4
                        mov     fbAddr3, fbAddr2
                        add     fbAddr3, #4
                        mov     fbAddr4, fbAddr3
                        add     fbAddr4, #4

                        ' clear the line buffer to black pixels
                        movd    :buffer, #lineBuffer
                        mov     cntX, #320
:buffer                 mov     0-0, black_pixel
                        add     :buffer, line_offset
                        djnz    cntX, #:buffer
                        
get_frame_color                                        
                        waitpne _null, pCamVSYNC        ' wait for VSYNC HIGH, indicates the start of a new frame
                        
                        mov     cntY, _fbRoiY      wz   ' cntY = ROI_Y
              if_nz     call    #wait_roi               ' if ROI_Y == 0, we don't need to skip any lines

                        mov     cntY, _fbClrY           ' Load counter variable with number of lines in frame            
get_line_color
                        waitpeq _null, pCamHREF         ' wait for HREF low

                        movd    :buffer0, #lineBuffer   ' setup line_buffer start
                        movd    :buffer1, #lineBuffer
                        movd    :buffer2, #lineBuffer
                        movd    :buffer3, #lineBuffer

                        mov     cntX, _fbClrX           ' Load counter variable with number of pixels per line 
                        shr     cntX, #2                ' divide by 4, since our loop does 4 pixels at a time
                        
                        waitpne _null, pCamHREF         ' wait for HREF high    (beginning of line)

                        waitpeq _null, pCamPCLK         ' wait for PCLK low     (skip first half of pixel in grey, we only want Y's)
                        
                        waitpne _null, pCamPCLK         ' wait for PCLK high    (first valid byte)
                        nop
                        
:get_pixels             mov     regA, ina               ' read the data                                 [4]
                        and     regA, #$FF              ' mask to just the pixel data                   [8]
                        nop                                                                            '[12]
:buffer0                mov     0-0, regA               ' store pixel in cog array                      [16]
                        add     :buffer0, line_offset   ' this adds 1 to the dest of the above mov      [20]
                        nop                                                                            '[24]

                        mov     regA, ina               ' read the data                                 [4]
                        and     regA, #$FF              ' mask to just the pixel data                   [8]
                        shl     regA, #8                ' shift up to the right place                   [12]
:buffer1                or      0-0, regA               ' store pixel in cog array                      [16]
                        add     :buffer1, line_offset   ' this adds 1 to the dest of the above or       [20]
                        nop                                                                            '[24]
                        
                        mov     regA, ina               ' read the data                                 [4]
                        and     regA, #$FF              ' mask to just the pixel data                   [8]
                        shl     regA, #16               ' shift up to the right place                   [12]
:buffer2                or      0-0, regA               ' store pixel in cog array                      [16]
                        add     :buffer2, line_offset   ' this adds 1 to the dest of the above or       [20]
                        nop                                                                            '[24]
                        
                        mov     regA, ina               ' read the data                                 [4]
                        and     regA, #$FF              ' mask to just the pixel data                   [8]
                        shl     regA, #24               ' shift up to the right place                   [12]
:buffer3                or      0-0, regA               ' store pixel in cog array                      [16]
                        add     :buffer3, line_offset   ' this adds 1 to the dest of the above or       [20]
                        djnz    cntX, #:get_pixels      ' cntX--                                        [24]

                        call    #store_line             ' store the line we just read into hub memory
                        
                        djnz    cntY, #get_line_color   ' cntY--

                        mov     fbAddr, par             ' get fb address again
                        
                        add     fbAddr, _fbSize         ' adjust pointer to just after fb (where done flag is)                                                        
                        add     fbAddr, _fbSize                                                        
                        add     fbAddr, _fbSize                                                        
                        add     fbAddr, _fbSize
                                                                                
                        cogid   regA                    ' Get our cog ID
                        wrlong  regA, fbAddr            ' Write flag to Done variable to indicate frame grab is complete
                        cogstop regA                    ' Stop the cog
                        ' SINCE THE COG HAS STOPPED, THE PROGRAM ENDS HERE

' SUBROUTINES
wait_roi                waitpeq _null, pCamHREF         ' Wait for HREF to go LOW
                        waitpne _null, pCamHREF         ' Wait for HREF to go HIGH
                        sub     cntY, #1           wz   ' cntY--   
              if_nz     jmp     #wait_roi        
wait_roi_ret            ret


store_line              movd    :buffer, #lineBuffer    ' init the cog read move instruction
                        mov     cntX, _fbClrX           ' Load counter variable with number of pixels per line 
                        shr     cntX, #2                ' divide by 4, since our loop does 4 (1byte) pixels (1 long) at a time
:buffer                 wrlong  0-0, fbAddr             ' store the long in the frame buffer
                        add     :buffer, line_offset    ' add 1 to the dest field of the above wrlong instruction
                        add     fbAddr, #4              ' advance fbAddr by a long
                        djnz    cntX, #:buffer          ' cntX--
store_line_ret          ret


' CONSTANTS
_null                   long    0
PINS                    long    %00000000_00000000_10000000_00000000     ' Pin I/O configuration, all inputs (for this cog) except P15
pLaserEn                long    %00000000_00000000_10000000_00000000     ' Mask: P15
pCamPCLK                long    %00000000_00000000_00100000_00000000     ' Mask: P13 
pCamVSYNC               long    %00000000_00000000_00010000_00000000     ' Mask: P12
pCamHREF                long    %00000000_00000000_00001000_00000000     ' Mask: P11
'pCamDATA                long    %00000000_00000000_00000000_11111111     ' Mask: P7..0 (D7..D0) (MSB..LSB)
_fbSize                 long    g#FB_SIZE
_fbClrX                 long    g#FB_CLR_X
_fbClrY                 long    g#FB_CLR_Y
_fbRoiY                 long    g#ROI_Y
line_offset             long    %00000000_00000000_00000010_00000000 ' used to add 1 to the destination field of an instruction
line_offsets            long    %00000000_00000000_00000000_00000001 ' used to add 1 to the source field of an instruction
black_pixel             long    %00000000_10000000_00000000_10000000
_xF0F0                  long    $FF00FF00 
_x0808                  long    $00800080 

' VARIABLES stored in cog RAM (uninitialized)
fbAddr                  res     1                       ' Address of hub RAM's frame buffer (passed from calling object in Start method)
fbAddr2                 res     1                       ' Address of hub RAM's frame buffer (passed from calling object in Start method)
fbAddr3                 res     1                       ' Address of hub RAM's frame buffer (passed from calling object in Start method)
fbAddr4                 res     1                       ' Address of hub RAM's frame buffer (passed from calling object in Start method)
regA                    res     1                       ' Value of Register A
cntY                    res     1                       ' Line count of the current frame
cntX                    res     1                       ' Pixel count of the current line

lineBuffer              res     80                      ' 320 byte buffer.

                        fit   ' make sure all instructions/data fit within the cog's RAM
                          