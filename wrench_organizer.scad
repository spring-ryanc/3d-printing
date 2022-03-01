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

extraWidth = 0.25; // Percentage wider, up to maxExtraWidth.
maxExtraWidth = 2; // Max extra padding in mm.
wrenchSlotLength=240; // Length of negative space wrench slots.
wrenchSegmentRotationDegrees = 20; // How much to rotate wrench lots from vertical.
baseHeight = 5; // Height offset for largest wrench in mm.

topAngleDegrees = -3;

trimOffset = -1; // Offset to ensure difference is cut cleanly by extending past the ends/sides.

startWidth = 150;
endWidth = 85;
rackSideThickness = 5;

module createOrganizer(dimensions) {    
    rackHeightStart = baseHeight + dimensions[0][2] + dimensions[0][1];
    rackHeightEnd = baseHeight + dimensions[len(dimensions) - 1][2] + dimensions[len(dimensions) - 1][1];
    rackLength = getOffset(len(dimensions) - 1, dimensions) + (getOffset(len(dimensions) - 1, dimensions) - getOffset(len(dimensions) - 2, dimensions)) + min(dimensions[len(dimensions) - 1][1], maxExtraWidth);

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
        }

        // Remove top to angle.
        rotate([topAngleDegrees, 0, 0]) // TODO: calculate degrees with... MATH.
            translate([trimOffset, 0, rackHeightStart]) // Offset by 1 and add 2 width for clean cuts.
                cube([startWidth + 2, rackLength + rackSideThickness, 15]); // 15 is a random number that is tall enough.

        // Remove slots for wrenches.
        for (wrench = dimensions)
        {
            offset = getOffset(wrench[0], dimensions); // Get Y offset.
            wrenchSegment(wrench[0], wrench[1], wrench[2], dimensions[0][2], offset);
        }
    }
};

module rackSide(rackHeightStart, rackHeightEnd, rackLength)
{
    rotationAngle = asin(((startWidth - endWidth) / 2) / sqrt(((startWidth - endWidth) / 2) ^ 2 + rackLength ^ 2));
    extraLength = 10; // Extend past end length and cut off, just needs to be long enough.
    translate([0, rackSideThickness, 0]) // Start after front of frame, remove extra when trimming later.
        difference()
        {
            rotate([0, 0, -rotationAngle])
                cube([rackSideThickness, rackLength + extraLength, rackHeightStart]); // Side.
            translate([trimOffset, -rackSideThickness, trimOffset]) // Offset for cleaner trimming.
                cube([rackSideThickness + 2, rackSideThickness, rackHeightStart + 2]); // Trim starting edge flat.
            translate([trimOffset, rackLength - rackSideThickness, trimOffset])
                cube([100, rackSideThickness + extraLength, rackHeightStart + 2]); // Trim ending edge flat, 100 to compensate for rotation.    
        }
};

module wrenchSegment(index, width, height, maxHeight, offset)
{
    width = slotWidth(width);
    
    // Move left for trimming, forward to wrench offset, up to center line.
    translate([trimOffset, offset, baseHeight + ((maxHeight - height) / 2)])
        rotate([wrenchSegmentRotationDegrees, 0, 0])
            union()
            {
                // Base cube.
                translate([0, 0, width/2])
                    cube([wrenchSlotLength, width, height + 1]); // +1 to extend into top.

                // Rounded bottom.
                translate([0, width/2, width/2])
                    rotate([0, 90, 0]) // Lay flat.
                        cylinder(wrenchSlotLength, r=width/2, center=false, $fn=64);

                // Top cube,
                translate([0, 0, (width/2) + height])
                    cube([wrenchSlotLength, width * 2, width * 2]);

                // Side cube minus cylinder for filet (top quater only).
                translate([0, width, (width/2) + height - (width * 2) ]) // Minus height to match top of base cube.
                    difference()
                    {
                        translate([0, trimOffset, 0]) // Extend into side of main cube.
                            cube([wrenchSlotLength, (width * 2) + 1, (width * 2) + 1]); // +1 to extend into top.
                        translate([trimOffset, width, width])
                            rotate([0, 90, 0]) // Lay flat.
                                cylinder(wrenchSlotLength + 2, r=width, center=false, $fn=64);
                        // Remove side portion.
                        translate([trimOffset, width, trimOffset])
                            cube([wrenchSlotLength + 2, width + 2, (width *2) + 3]);
                        // Remove bottom portion.
                        translate([trimOffset,  trimOffset, trimOffset])
                            cube([wrenchSlotLength + 2, width + 2, (width) + 1]);
                    }
            };                          
};


// Messing around with adding slotWidth(metricSmall[index - 1][1]) or instead of const 4

function getOffset(index, dimensions) = (index==0 ? dimensions[index][2] : slotWidth(dimensions[index - 1][1]) + slotWidth(dimensions[index - 1][1]) + getOffset(index-1, dimensions));

function slotWidth(width) = min(width * (1 + extraWidth), width + maxExtraWidth);

createOrganizer(metricSmall);

translate([200, 0, 0])
    createOrganizer(metricLarge);