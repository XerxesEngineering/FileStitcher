//
//  ProgressStepDelegate.h
//  FileStitcher
//
//  Created by Kevin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ProgressStepDelegate <NSObject>

-(void)performProgressStep:(double)progressStep;
-(void)progressComplete;

@end
