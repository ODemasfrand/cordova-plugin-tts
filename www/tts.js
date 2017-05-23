/*

    Cordova Text-to-Speech Plugin
    https://github.com/vilic/cordova-plugin-tts

    by VILIC VANE
    https://github.com/vilic

    MIT License

*/

var exec = require('cordova/exec');

var TTS = {};

TTS.speak = function (text) {
    var options = {};

    if (typeof text == 'string')
        options.text = text;
    else
        options = text;

    return new Promise(function(resolve, reject){
        exec(resolve, reject, 'TTS', 'speak', [options]);
    });
};

TTS.stop = function() {
    return new Promise(function(resolve, reject){
        exec(resolve, reject, 'TTS', 'stop', [])
    });
};

TTS.getVoices = function(){
    return new Promise(function(resolve, reject){
        exec(resolve, reject, 'TTS', 'getVoices', []);
    });
};

module.exports = TTS;