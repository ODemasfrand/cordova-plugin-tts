/*
 Cordova Text-to-Speech Plugin
 https://github.com/vilic/cordova-plugin-tts

 by VILIC VANE
 https://github.com/vilic

 MIT License
 */

#import <Cordova/CDV.h>
#import "CDVTTS.h"

NSString * LANGUAGE_KEY = @"language";
NSString * NAME_KEY = @"name";

@implementation CDVTTS

- (void)pluginInitialize {
    synthesizer = [AVSpeechSynthesizer new];
    synthesizer.delegate = self;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance*)utterance {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    if (lastCallbackId) {
        [self.commandDelegate sendPluginResult:result callbackId:lastCallbackId];
        lastCallbackId = nil;
    } else {
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        callbackId = nil;
    }

    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient
                                     withOptions: 0 error: nil];
    [[AVAudioSession sharedInstance] setActive:YES withOptions: 0 error:nil];
}

- (void)speak:(CDVInvokedUrlCommand*)command {
    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];

    if (callbackId)
        lastCallbackId = callbackId;

    callbackId = command.callbackId;

    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    NSDictionary* options = [command.arguments objectAtIndex:0];

    NSString* text = [options objectForKey:@"text"];
    NSString* locale = [options objectForKey:@"locale"];
    double pitch = [[options objectForKey:@"pitch"] doubleValue];
    double rate = [[options objectForKey:@"rate"] doubleValue];

    if (!locale || (id)locale == [NSNull null])
        locale = @"en-US";

    if (!rate && rate != 0)
        rate = AVSpeechUtteranceDefaultSpeechRate;
    else
        rate = ((rate / 100) * (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate)) + AVSpeechUtteranceMinimumSpeechRate;

    if (!pitch && pitch != 0)
        pitch = 100;
    else if(pitch < 50)
        pitch = 50;

    AVSpeechUtterance* utterance = [[AVSpeechUtterance new] initWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage: locale];

    utterance.rate = rate;
    utterance.pitchMultiplier = pitch / 100;

    [synthesizer speakUtterance:utterance];
}

- (void)stop:(CDVInvokedUrlCommand*)command {
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

- (void)getVoices:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        @try {
            NSArray *voices = [AVSpeechSynthesisVoice speechVoices];
            NSMutableArray *jsonArray = [[NSMutableArray alloc] init];
            for(AVSpeechSynthesisVoice *voice in voices)
                [jsonArray addObject: [self toJSON: voice]];

            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsArray: jsonArray];
        } @catch(NSException *e){
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR];
        }

        [self.commandDelegate sendPluginResult: pluginResult  callbackId: command.callbackId];
    }];
}

- (NSString *) toJSON: (AVSpeechSynthesisVoice *) voice {
    NSError *error;
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue: voice.language forKey: LANGUAGE_KEY];
    [dictionary setValue: voice.name forKey: NAME_KEY];

    NSData *json = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error: &error];
    return [[NSString alloc] initWithData:json encoding: NSUTF8StringEncoding];
}

@end
