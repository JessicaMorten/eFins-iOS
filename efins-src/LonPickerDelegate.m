//
//  LonPickerDelegate.m
//  eFins-iOS
//
//  Created by Todd Bryan on 8/13/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

#import "LonPickerDelegate.h"
#import "CLLocation+FESCoordinates.h"


@implementation LonPickerDelegate

- (void) configurePickerView:(UIPickerView *)pickerView {
    pickerView.delegate = self;
    pickerView.dataSource = self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return 359;
    } else if (component == 1) {
        return 60;
    } else if (component == 2) {
        return 100;
    } else {
        return 0;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view    {
    UILabel *label = (id)view;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [pickerView rowSizeForComponent:component].width - 10.0f, [pickerView rowSizeForComponent:component].height)];
    }
    
    if (component == 0) {
        label.text =[NSString stringWithFormat:@"%ld \u00b0  ", (long)row - 179];
        label.textAlignment = NSTextAlignmentRight;
    } else if (component == 1) {
        label.text = [NSString stringWithFormat:@"%ld.", (long)row];
        label.textAlignment = NSTextAlignmentRight;
    } else if (component == 2) {
        label.text = [NSString stringWithFormat:@"%02ld \u2032", (long)row];
        label.textAlignment = NSTextAlignmentLeft;
    }
    return label;
}

- (void) actionSheetPickerDidSucceed:(AbstractActionSheetPicker *)actionSheetPicker origin:(id)origin {
    ActionSheetCustomPicker *picker = (ActionSheetCustomPicker *)actionSheetPicker;
    UIPickerView *pick = (UIPickerView *)picker.pickerView;
    NSInteger lonDeg = [pick selectedRowInComponent:0] - 179;
    NSNumber *lonMinInt = [NSNumber numberWithLong:[pick selectedRowInComponent:1]];
    NSNumber *lonMinDec = [NSNumber numberWithLong:[pick selectedRowInComponent:2]];
    NSNumber *minutes = [NSNumber numberWithDouble:([lonMinInt doubleValue] + [lonMinDec doubleValue] / 100.0 )];
    
    FESLocationDegreesMinDec minDec;
    minDec.degrees = lonDeg;
    minDec.minutes = [minutes doubleValue];
    NSNumber *lon = [NSNumber numberWithDouble:[CLLocation fes_decimalDegreesForDegreesMinDec:minDec]];
    [self.receiver performSelector:self.selectorToPerform withObject:lon afterDelay:0];
}



@end


