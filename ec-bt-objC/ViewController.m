//
//  ViewController.m
//  ec-bt-objC
//
//  Created by Kumari, Reena on 2/18/19.
//  Copyright © 2019 Kumari, Reena. All rights reserved.
//

#import "ViewController.h"
#import "BraintreePayPal.h"

@interface ViewController ()<BTAppSwitchDelegate, BTViewControllerPresentingDelegate>
@property (nonatomic, strong) BTAPIClient *braintreeClient;
@property (nonatomic, strong) BTPayPalDriver *payPalDriver;

@end

@implementation ViewController
NSString *BASE_URL = @"https://paypal-integration-sample.herokuapp.com";
NSString *CLIENT_TOKEN_URL = @"/api/paypal/ecbt/client_token";
NSString *CHECKOUT = @"/api/paypal/ecbt/checkout";

NSString *client_token;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getClientToken];
}

-(void) getClientToken {
    NSString *targetUrl = [NSString stringWithFormat:@"%@%@",BASE_URL,CLIENT_TOKEN_URL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          
          client_token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          NSLog(@"Data received: %@", client_token);
      }] resume];
}

- (IBAction)pay:(id)sender {
    self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:client_token];
    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithAPIClient:self.braintreeClient];
    payPalDriver.viewControllerPresentingDelegate = self;
    payPalDriver.appSwitchDelegate = self; // Optional
    
    // ...start the Checkout flow
    BTPayPalRequest *request = [[BTPayPalRequest alloc] initWithAmount:@"20.00"];
    request.currencyCode = @"USD";
    
    [payPalDriver requestOneTimePayment:request
                             completion:^(BTPayPalAccountNonce *tokenizedPayPalCheckout, NSError *error) {
                                 if (error) {
                                     [self displayAlertMessage:error.localizedDescription];
                                 } else if (tokenizedPayPalCheckout) {
                                     [self processCheckout:tokenizedPayPalCheckout];
                                 } else {
                                     [self displayAlertMessage:@"Cancelled"];
                                 }
                             }];
}

-(void) processCheckout: (BTPayPalAccountNonce *) tokenizedPayPalCheckout {
    NSLog(@"Got a nonce: %@", tokenizedPayPalCheckout.nonce);
    
    NSDictionary *requestBody = @{@"amount": @"20.00",
                                  @"nonce": tokenizedPayPalCheckout.nonce,
                                  @"currency":@"USD"
                                  };
    
    NSString *checkout = [NSString stringWithFormat: @"%@%@", BASE_URL, CHECKOUT];
    
    NSData *httpBody = [NSJSONSerialization dataWithJSONObject:requestBody options:kNilOptions error:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.HTTPMethod = @"POST";
    [request setURL:[NSURL URLWithString:checkout]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:httpBody];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable data,
                                                                NSURLResponse * _Nullable response,
                                                                NSError * _Nullable error) {
                                                NSLog(@"%@", data);
                                                
                                                NSString *res = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                
                                                NSLog(@"%@", res);
                                                [self displayAlertMessage:res];
                                }];
    [task resume];
    
}

- (void) displayAlertMessage: (NSString *) msg{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                    message:msg
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *userAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    
    [alert addAction:userAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - BTViewControllerPresentingDelegate

// Required
- (void)paymentDriver:(id)paymentDriver
requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

// Required
- (void)paymentDriver:(id)paymentDriver
requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - BTAppSwitchDelegate

// Optional - display and hide loading indicator UI
- (void)appSwitcherWillPerformAppSwitch:(id)appSwitcher {
    
   
}

- (void)appSwitcherWillProcessPaymentInfo:(id)appSwitcher {
}

@end
