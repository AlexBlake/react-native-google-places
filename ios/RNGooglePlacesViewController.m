#import "RNGooglePlacesViewController.h"
#import "NSMutableDictionary+GMSPlace.h"

#import <GooglePlaces/GooglePlaces.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

@interface RNGooglePlacesViewController ()<GMSAutocompleteViewControllerDelegate>
@end

@implementation RNGooglePlacesViewController
{
	RNGooglePlacesViewController *_instance;

	RCTPromiseResolveBlock _resolve;
	RCTPromiseRejectBlock _reject;
}

- (instancetype)init 
{
	self = [super init];
	_instance = self;

	return self;
}

- (void)openAutocompleteModal: (GMSAutocompleteFilter *)autocompleteFilter
                    placeFields: (GMSPlaceField)selectedFields
                       bounds: (GMSCoordinateBounds *)autocompleteBounds
                       boundsMode: (GMSAutocompleteBoundsMode)autocompleteBoundsMode
                     resolver: (RCTPromiseResolveBlock)resolve
                     rejecter: (RCTPromiseRejectBlock)reject
                     displayOptions: (NSDictionary *)displayOptions;
{
    _resolve = resolve;
    _reject = reject;
    
    GMSAutocompleteViewController *viewController = [[GMSAutocompleteViewController alloc] init];
    viewController.autocompleteFilter = autocompleteFilter;
    viewController.autocompleteBounds = autocompleteBounds;
    viewController.autocompleteBoundsMode = autocompleteBoundsMode;
    viewController.placeFields = selectedFields;
	viewController.delegate = self;

    NSArray *whiteList = @[
        @"tableCellBackgroundColor",
        @"tableCellSeparatorColor",
        @"primaryTextColor",
        @"primaryTextHighlightColor",
        @"secondaryTextColor",
        @"tintColor",
    ];
    NSPredicate *whitelistPredicate = [NSPredicate predicateWithFormat:@"self IN %@", whiteList];
    NSDictionary *whitelistedOptions = [displayOptions dictionaryWithValuesForKeys:[displayOptions.allKeys filteredArrayUsingPredicate:whitelistPredicate]];
    
    [whitelistedOptions enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL* stop) {
        [viewController setValue:[self hexStringToColor: value] forKey:key];
    }];

    UIViewController *topController = [self getTopController];
	[topController presentViewController:viewController animated:YES completion:nil];
}

// Handle the user's selection.
- (void)viewController:(GMSAutocompleteViewController *)viewController
	didAutocompleteWithPlace:(GMSPlace *)place 
{
    UIViewController *topController = [self getTopController];
    [topController dismissViewControllerAnimated:YES completion:nil];
	
	if (_resolve) {
        _resolve([NSMutableDictionary dictionaryWithGMSPlace:place]);
    }
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
	didFailAutocompleteWithError:(NSError *)error 
{
    UIViewController *topController = [self getTopController];
    [topController dismissViewControllerAnimated:YES completion:nil];

	// TODO: handle the error.
	NSLog(@"Error: %@", [error description]);

	_reject(@"E_AUTOCOMPLETE_ERROR", [error description], nil);
}

// User canceled the operation.
- (void)wasCancelled:(GMSAutocompleteViewController *)viewController 
{
    UIViewController *topController = [self getTopController];
    [topController dismissViewControllerAnimated:YES completion:nil];

	_reject(@"E_USER_CANCELED", @"Search cancelled", nil);
}

// Turn the network activity indicator on and off again.
- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController 
{
  	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController 
{
  	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// User canceled the operation.
- (UIViewController *)getTopController
{
    UIViewController *topController = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (topController.presentedViewController) { topController = topController.presentedViewController; }
    return topController;
}

- (UIColor *) hexStringToColor:(NSString *) color 
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:color];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end