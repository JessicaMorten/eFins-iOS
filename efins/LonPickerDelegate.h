//
//  LonPickerDelegate.h
//  eFins-iOS
//
//  Created by Todd Bryan on 8/13/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActionSheetPicker.h"

@interface LonPickerDelegate: NSObject <ActionSheetCustomPickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, weak) NSObject *receiver;
@property (nonatomic) SEL selectorToPerform;
@end

