// Index, width, height. Must be sorted by wrench size.
metricSmall = [
    [0, 5.4, 13.6],
    [1, 4.9, 12.5],
    [2, 4.4, 12.4],
    [3, 4.8, 11.3],
    [4, 4.3, 10.3],
    [5, 4.1, 9.6],
    [6, 3.5, 8.1],
    [7, 3.4, 6.9],
    [8, 3.4, 6.6],
];

metricLarge = [
    [0, 7.7, 20.7],
    [1, 7.0, 19.3],
    [2, 6.5, 17.6],
    [3, 6.5, 16.9],
    [4, 6.2, 15.6],
    [5, 5.9, 15.0],
];

extraSlotWidth = 0.25; // Percentage wider to make slots based on wrench width, up to maxExtraSlotWidth.
maxExtraSlotWidth = 2; // Max extra padding for slots in mm.
rackSideThickness = 5; // Wall thickness in mm.

// TODO: it would be nice to make these parameters to the module so the larger sets can be wider at the same time.
// TODO: consider setting length and deriving offset from that.
startWidth = 150; // Width of large end of rack.
endWidth = 85; // Width of small end of rack.
wrenchSlotRotationDegrees = 20; // How much to rotate wrench lots from vertical.
baseHeight = 5; // Height offset for largest wrench in mm (ensure wrench ends don't hit floor).
startOffset = 15; // Base offset for first slot from front (large) end of rack.

topAngleDegrees = -3; // Use to trim top angle. TODO: calculate with.. MATH
trimOffset = -1; // Offset to ensure difference is cut cleanly by extending past the ends/sides.

// createOrganizer(metricSmall, 120);

// translate([200, 0, 0])
//     createOrganizer(metricSmall, 140);

// Large wrenches.
baseHeight = 6;
wrenchSlotRotationDegrees = 50;
startOffset = 40;
startWidth = 200; // Width of large end of rack.
endWidth = 150; // Width of small end of rack.

createOrganizer(metricLarge, 170);

// translate([200, 0, 0])
//     createOrganizer(metricLarge, 180);

// Height of largest is used as base offset.
// function getOffset(index, dimensions, rackLength) = (index==0 ? startOffset : (slotWidth(dimensions[index - 1][1]) * (2+sin(wrenchSlotRotationDegrees))) + getOffset(index-1, dimensions, rackLength));
function getOffset(index, dimensions, rackLength) = (index==0 ? startOffset : ( ((rackLength ) / len(dimensions)) - (dimensions[index][1] * ((index+1)/len(dimensions)))) + getOffset(index-1, dimensions, rackLength));

function slotWidth(width) = min(width * (1 + extraSlotWidth), width + maxExtraSlotWidth);

function sideRotation(startWidth, endWidth, rackLength) = asin(((startWidth - endWidth) / 2) / sqrt(((startWidth - endWidth) / 2) ^ 2 + rackLength ^ 2));

module createOrganizer(dimensions, rackLength=100) {    
    rackHeightStart = baseHeight + dimensions[0][2] + dimensions[0][1];
    rackHeightEnd = baseHeight + dimensions[len(dimensions) - 1][2] + dimensions[len(dimensions) - 1][1];

    // Offset of last wrench + size of offset from second last wrench + slot size of last wrench or max extra width (just reused to keep it short).
    // rackLength = getOffset(len(dimensions) - 1, dimensions) + (getOffset(len(dimensions) - 1, dimensions) - getOffset(len(dimensions) - 2, dimensions)) + min(dimensions[len(dimensions) - 1][1], maxExtraSlotWidth);
    // Try to use relative size based on angle.
    // rackLength = getOffset(len(dimensions) - 1, dimensions) + (dimensions[len(dimensions) - 1][1] * (1 + +sin(wrenchSlotRotationDegrees))); // + (getOffset(len(dimensions) - 1, dimensions) - getOffset(len(dimensions) - 2, dimensions)) + min(dimensions[len(dimensions) - 1][1], maxExtraSlotWidth);

    braceSize = 20;
    angle = -sideRotation(startWidth, endWidth, rackLength);
    difference()
    {

        // Base frame.
        union()
        {
            cube([startWidth, rackSideThickness, rackHeightStart]); // Home end of rack.

            translate([(startWidth - endWidth) / 2, rackLength - rackSideThickness, 0]) // Center and move to end.
                cube([endWidth, rackSideThickness, rackHeightStart]); // Far end of rack.

            rackSide(rackHeightStart, rackHeightEnd, rackLength); // Left side.

            translate([startWidth, 0, 0]) // Move to right, mirror (flip) and create right side.
                mirror([1, 0, 0])
                    rackSide(rackHeightStart, rackHeightEnd, rackLength);
        
            
            // Far left corner brace.
            frontBrace(braceSize, 5, angle);
            
            // Far right corner brace.
            translate([startWidth, 0, 0]) // Center and move to end.
                mirror([1, 0, 0])
                    frontBrace(braceSize, 5, angle);

            
            // Far left corner brace.
            translate([((startWidth - endWidth) / 2) + braceSize, rackLength - rackSideThickness, 0])
                mirror([1, 0, 0])
                    endBrace(braceSize, 5, angle);
            
            // Far right corner brace.
            translate([((startWidth - endWidth) / 2) + endWidth - braceSize, rackLength - rackSideThickness, 0]) // Center and move to end.
                endBrace(braceSize, 5, angle);
        }

        // Remove top to angle.
        rotate([topAngleDegrees, 0, 0])
            translate([trimOffset, 0, rackHeightStart]) // Offset by 1 and add 2 width for clean cuts.
                cube([startWidth + 2, rackLength + rackSideThickness, 15]); // 15 is a random number that is tall enough.

        // Remove slots for wrenches.
        for (wrench = dimensions)
        {
            offset = getOffset(wrench[0], dimensions, rackLength); // Get Y offset.
            wrenchSegment(wrench[0], wrench[1], wrench[2], dimensions[0][2], offset);
        }
    }
};

module rackSide(rackHeightStart, rackHeightEnd, rackLength)
{
    extraLength = 10; // Extend past end length and cut off, just needs to be long enough.
    translate([0, rackSideThickness, 0]) // Start after front of frame, remove extra when trimming later.
        difference()
        {
            rotate([0, 0, -sideRotation(startWidth, endWidth, rackLength)])
                cube([rackSideThickness, rackLength + extraLength, rackHeightStart]); // Side.
            translate([trimOffset, -rackSideThickness, trimOffset]) // Offset for cleaner trimming.
                cube([rackSideThickness + 2, rackSideThickness, rackHeightStart + 2]); // Trim starting edge flat.
            translate([trimOffset, rackLength - rackSideThickness, trimOffset])
                cube([100, rackSideThickness + extraLength, rackHeightStart + 2]); // Trim ending edge flat, 100 to compensate for rotation.    
        }
};

module endBrace(size, height, angle) {
    extraWidth = sqrt(((size/cos(angle))^2) - (size^2));
    mirror([0, 1, 0])
    difference()
    {
        union()
        {
            cube([size, size, height]);
        
            translate([size, 0, 0])
                difference()
                {
                    cube([size, size, height]);
                    rotate([0,0,angle])
                        translate([0, 0, -1])
                            cube([size*2, size*2, height+2]);
                }
        }
        translate([0, -extraWidth, -1])
            rotate([0,0,45])            
                cube([size*2, size*2, height+2]);
    }
}

module frontBrace(size, height, angle) {
    translate([size, 0, 0])
        mirror([1, 0, 0])
            difference()
            {
                cube([size, size, height]);
                
                translate([size, 0, -1])
                    rotate([0,0,-angle])
                        cube([size*2, size*2, height+2]);
                        
                translate([0, 0, -1])
                    rotate([0,0,60])            
                        cube([size*2, size*2, height+2]);
            }    
}

module wrenchSegment(index, width, height, maxHeight, offset)
{
    width = slotWidth(width);
    length = startWidth + 10; // Extra for clean trimming;
    
    // Move left for trimming, forward to wrench offset, up to center line.
    translate([trimOffset, offset, baseHeight + ((maxHeight - height) / 2)])
        rotate([wrenchSlotRotationDegrees, 0, 0])
            union()
            {
                // Base cube.
                translate([0, 0, width/2])
                    cube([length, width, height + 1]); // +1 to extend into top.

                // Rounded bottom.
                translate([0, width/2, width/2])
                    rotate([0, 90, 0]) // Lay flat.
                        cylinder(length, r=width/2, center=false, $fn=64);

                // Top cube,
                translate([0, 0, (width/2) + height])
                    cube([length, width * 2, width * 2]);

                // Side cube minus cylinder for filet (top quater only).
                translate([0, width, (width/2) + height - (width * 2) ]) // Minus height to match top of base cube.
                    difference()
                    {
                        translate([0, trimOffset, 0]) // Extend into side of main cube.
                            cube([length, (width * 2) + 1, (width * 2) + 1]); // +1 to extend into top.
                        translate([trimOffset, width, width])
                            rotate([0, 90, 0]) // Lay flat.
                                cylinder(length + 2, r=width, center=false, $fn=64);
                        // Remove side portion.
                        translate([trimOffset, width, trimOffset])
                            cube([length + 2, width + 2, (width *2) + 3]);
                        // Remove bottom portion.
                        translate([trimOffset,  trimOffset, trimOffset])
                            cube([length + 2, width + 2, (width) + 1]);
                    }
            };                 
};

// Attempting to figure out x size of slots after rotation.. not working well.
// c = a/cos(angleA)
// b = sqrt(c^2 - a ^2)
function actualWidth(width, height) = sqrt(((height/cos(90-45))^2) - (height^2));
