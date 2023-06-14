//
//  Document.h
//  Cytosim GUI
//
//  Created by Chris on 14/08/2022.
//

#import <Cocoa/Cocoa.h>
#import "VConfigurationModel.h"
#import "OrderedDictionary.h"
#import "VParamVariationsManager.h"

@interface VDocument : NSDocument <NSTextViewDelegate, NSTextStorageDelegate, NSTextDelegate, NSLayoutManagerDelegate, NSToolbarDelegate>

// configuration text
@property (strong)          VConfigurationModel*            configModel;
@property (strong) IBOutlet NSTextView*                     configTextView;
@property (assign)          BOOL                            wantsSyntaxColor;
//@property (assign)          NSRange                         visibleTextRange;
// the next 2 are just to keep a reference to these objects to accelerate text coloring and positioning
@property (strong) IBOutlet NSScrollView*                   scrollView;
@property (strong) IBOutlet NSClipView*                     clipView;

@property (strong) IBOutlet NSToolbar*                      toolbar;
@property (strong) IBOutlet NSPopUpButton*                  objectsButton;
// Parameter variations
@property (strong) IBOutlet NSWindow*                       variationsWindow;
@property (strong)          OrderedDictionary*              paramDic;
@property (strong) IBOutlet VParamVariationsManager*        paramVarMgr;
@property (strong)          NSNumber*                       canRunBatchSim;

- (void) replaceWithText:(NSString*) newText;
- (IBAction) choseTextColors: (id) sender;
- (IBAction) blockComment:(id) sender;
- (IBAction) indentSelection:(id)sender;
- (IBAction) deIndentSelection:(id)sender;
- (IBAction) openModelBuilder: (id) sender;
- (IBAction) printConfigurationFile:(id)sender;

- (IBAction) showVariationsWindow: (id) sender;
- (IBAction) goToObjectItem:(id)sender;
- (IBAction) parseAgain:(id)sender;
- (IBAction) toggleSyntaxColoring:(id)sender;
@end

