//
//  NSArray+HLSExtensions.h
//  CoconutKit
//
//  Created by Samuel Défago on 2/24/11.
//  Copyright 2011 Hortis. All rights reserved.
//

@interface NSArray (HLSExtensions)

/**
 * Returns the first object in the array, or nil if the array is empty
 *
 * Remark: A private -firstObject method exists since iOS 4
 */
- (id)firstObject_hls;

/**
 * Return a copy of the receiver with array elements rotated to the left or right (elements disappearing 
 * at an end are moved to the other end)
 */
- (NSArray *)arrayByLeftRotatingNumberOfObjects:(NSUInteger)numberOfElements;
- (NSArray *)arrayByRightRotatingNumberOfObjects:(NSUInteger)numberOfElements;

/**
 * Rotate a copy of the receiver with the specified object removed
 */
- (NSArray *)arrayByRemovingObjectAtIndex:(NSUInteger)index;
- (NSArray *)arrayByRemovingObject:(id)object;

/**
 * Return a copy of the receiver, sorted using a single descriptor
 */
- (NSArray *)sortedArrayUsingDescriptor:(NSSortDescriptor *)sortDescriptor;

@end
