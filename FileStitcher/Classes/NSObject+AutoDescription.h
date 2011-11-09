//
//  NSObject+AutoDescription.h
//
//  Created by Andrew on 26/3/11.
//  Copyright 2011 ATKit. All rights reserved.
//

#import <Foundation/Foundation.h>

// Description based on Reflection, Format: [ClassName {prop1 = val1; prop2 = val2; }]., SuperClass' properties included (until NSObject).
@interface NSObject(AutoDescription)

// Reflects about self.
- (NSString *) autoDescription; // can be in real description or somewhere else

@end

/* Usage:

// Somewhere in AnyObject
- (NSString *)description {
	return [self autoDescription];
}

and: NSLog(@"My AnyObject: %@", anyObject);

Or Just: NSLog(@"My AnyObject: %@", [anyObject autoDescription]);

*/