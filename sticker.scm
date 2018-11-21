(script-fu-register
    "script-fu-border"                          ;function name
    "Turn selection into sticker"               ;menu label
    "Isolates selection and draws a border around it. Optionally crops the picture afterwards" ;description    
    "Thomas Fuhrt"                              ;author
    "GNU Public license"                        ;copyright notice
    "November, 21, 2018"                        ;date created
    "RGB, RGBA"                                 ;image the script works on
    SF-IMAGE  "Image"  0                        ;Image
    SF-DRAWABLE "Layer" 0                       ;Layer
    SF-VALUE  "Width"  "5"
    SF-COLOR  "Color"   '(255 255 255)
    SF-TOGGLE "Crop around Edge" TRUE         ;if TRUE crops the image around the edge
    SF-TOGGLE "Add Space if needed" TRUE      ;if TRUE adds additional space to the image for the border in case the selection is closer than width to the edge of the image
)
(script-fu-menu-register "script-fu-border" "<Image>/Filters/Sticker")
(define (script-fu-border image layer width color crop? addSpace?)
    (let*
        (
        ;define local variables
        (old_color      (car (gimp-context-get-foreground)))
        (imageWidth     (car (gimp-image-width image)))
        (imageHeight    (car (gimp-image-height image)))
        (layerHeight    (car (gimp-drawable-height layer)))
        (layerWidth     (car (gimp-drawable-width layer)))
        ) ;end local variables
        ;add alpha channel if not existent
        (gimp-layer-add-alpha layer)    
        ;add additional pixels to the image if selection too close to the edge and user wishes so
        (when (equal? addSpace? TRUE)
            (let*
                (
                (x1                 (cadr (gimp-selection-bounds image)))
                (y1                 (caddr (gimp-selection-bounds image)))
                (x2                 (cadddr (gimp-selection-bounds image)))
                (y2                 (cadddr (cdr (gimp-selection-bounds image))))
                (selectionWidth     (- x2 x1))
                (selectionHeight    (- y2 y1))
                (leftDelta          (- x1 width))
                (rightDelta         (- (- imageWidth x2) width))
                (topDelta           (- y1 width))
                (botDelta           (- (- imageHeight y2) width))
                (additionalSpaceX1  0);The space to be added to the left   edge
                (additionalSpaceY1  0);The space to be added to the top    edge
                (additionalSpaceX2  0);The space to be added to the right  edge
                (additionalSpaceY2  0);The space to be added to the bottom edge
                )                
                ;Find edges that are too close to selection
                (when (< leftDelta 0) 
                    (set! additionalSpaceX1 (+ additionalSpaceX1 (* leftDelta -1)))
                )
                (when (< topDelta 0) 
                    (set! additionalSpaceY1 (+ additionalSpaceY1 (* topDelta -1)))
                )
                (when (< rightDelta 0) 
                    (set! additionalSpaceX2 (+ additionalSpaceX2 (* rightDelta -1)))
                )
                (when (< botDelta 0) 
                    (set! additionalSpaceY2 (+ additionalSpaceY2 (* botDelta -1)))
                )
                ;if edges are too close add in additional space
                (when (not (and (= 0 additionalSpaceX1) (= 0 additionalSpaceX2) 
                                (= 0 additionalSpaceY1) (= 0 additionalSpaceY2)))
                    (gimp-image-resize image (+ imageWidth additionalSpaceX1 additionalSpaceX2)
                                            (+ imageHeight additionalSpaceY1 additionalSpaceY2)
                                            0 0)
                    (gimp-layer-translate layer additionalSpaceX1 additionalSpaceY1)
                    (gimp-selection-translate image additionalSpaceX1 additionalSpaceY1)
                
                    (gimp-layer-resize-to-image-size layer)
                )
            )            
        )
        ;Fill inverted selection by chosen color, then reset context color to the old value
        (gimp-selection-invert image)        
        (gimp-context-set-foreground color)
        (gimp-edit-fill layer 0)
        (gimp-context-set-foreground old_color)
        ;clear the outer space around the border
        (gimp-selection-invert image)
        (gimp-selection-grow image width)
        (gimp-selection-invert image)
        (gimp-edit-clear layer)
        ;reset selection to float around sticker with border
        (gimp-selection-invert image)
        ;crop the image around the selection if selected by user
        (if (equal? crop? TRUE)
            (let*
                (
                (x1               (cadr (gimp-selection-bounds image)))
                (y1               (caddr (gimp-selection-bounds image)))
                (x2               (cadddr (gimp-selection-bounds image)))
                (y2               (cadddr (cdr (gimp-selection-bounds image))))
                (selectionWidth   (- x2 x1))
                (selectionHeight  (- y2 y1))
                )
                (gimp-image-crop image selectionWidth selectionHeight x1 y1)
            )
        )
        ;update the display
        (gimp-displays-flush)
        (list image layer)
    )
)
;(gimp-display-new image) ;This creates a new display
