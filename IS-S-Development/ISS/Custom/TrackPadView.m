//
//  TrackPadView.m
//  KeyBoardTest
//
//  Created by Anshuman Dahale on 5/20/16.
//  Copyright © 2016 Silicus. All rights reserved.
//

#import "TrackPadView.h"

@interface TrackPadView () {
    
    CGPoint firstPoint, lastPoint;
    BOOL mouseSwiped;
}

@property (nonatomic, strong) IBOutlet UIImageView *drawImageView;
@property (nonatomic, strong) IBOutlet UILabel *coordinateLabel;

@end


@implementation TrackPadView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    if(!_hideCoordinatesLabel) {
        
        self.coordinateLabel = [[UILabel alloc] initWithFrame:CGRectMake
                                                            (0, 0, self.frame.size.width, 10)];
        self.coordinateLabel.alpha = 0.5;
        self.coordinateLabel.font = [UIFont systemFontOfSize:10];
        self.coordinateLabel.textColor = [UIColor blackColor];
        [self addSubview:self.coordinateLabel];
    }
}


- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSLog(@"Touches began");
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    firstPoint = [touch locationInView:self];
    NSLog(@"(X: %f, Y: %f)", firstPoint.x, firstPoint.y);
}

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    
    if(CGRectContainsPoint(self.drawImageView.frame, currentPoint)) {
        
        CGPoint simulatedPoint = [self getSimulatedCoordinatesFromPoint:currentPoint];
        
        if(!_hideCoordinatesLabel) {
            self.coordinateLabel.text = [NSString stringWithFormat:@"(X:%.2f, Y:%.2f)", simulatedPoint.x, simulatedPoint.y];
            lastPoint = simulatedPoint;
        }
//        if([self.touchDelegate respondsToSelector:@selector(userTouchedOnPoint:)]) {
//            
////            NSLog(@"(X: %f, Y: %f)", lastPoint.x, lastPoint.y);
////            [self.touchDelegate userTouchedOnPoint:lastPoint];
//        }
    }
}


- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint endPoint = [touch locationInView:self];
    
    CGFloat adjustedFirstX = (NSInteger)(firstPoint.x / (self.frame.size.width/200));
    CGFloat adjustedFirstY = (NSInteger)(firstPoint.y / (self.frame.size.height/200));
    
    CGFloat adjustedEndX = (NSInteger)(endPoint.x / (self.frame.size.width/200));
    CGFloat adjustedEndY = (NSInteger)(endPoint.y / (self.frame.size.height/200));
    
    CGFloat deltaX = adjustedFirstX - adjustedEndX;
    CGFloat deltaY = adjustedFirstY - adjustedEndY;
    
    CGPoint delta =  CGPointMake(deltaX, deltaY);
    
    if([self.touchDelegate respondsToSelector:@selector(userTouchedOnPoint:)]) {
        [self.touchDelegate userTouchedOnPoint:delta];
    }
}


- (void) showPointOnLabelWithTouch:(UITouch *)touch {
    
}

- (CGPoint) getSimulatedCoordinatesFromPoint:(CGPoint)point {
    
    CGFloat y = -(point.y);
    CGFloat simulatedY = y + (self.frame.size.height / 2);
    
    CGPoint simulatedPoint = CGPointMake(point.x - self.frame.size.width / 2, simulatedY);
    
    CGFloat adjustedX = (NSInteger)(simulatedPoint.x / (self.frame.size.width/200));
    CGFloat adjustedY = (NSInteger)(simulatedPoint.y / (self.frame.size.height/200));
    
    CGPoint adjustedReturnPoint = CGPointMake(adjustedX, adjustedY);
    
    return adjustedReturnPoint;
}


@end
