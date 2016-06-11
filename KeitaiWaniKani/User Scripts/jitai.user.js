// ==UserScript==
// @name        Jitai
// @version     1.3.0
// @description Display WaniKani reviews in randomized fonts, for more varied reading training.
// @author      Samuel (@obskyr)
// @namespace   http://obskyr.io/
// @homepageURL https://gist.github.com/obskyr/9f3c77cf6bf663792c6e
// @icon        http://i.imgur.com/qyuR9bD.png
// @include     /^https?://(www\.)?wanikani\.com/review/session/?$/
// @grant       none
// ==/UserScript==

/*
    To control which fonts to choose from, edit this list.
    If you feel too many fonts of a certain type are showing
    up, remove a few of those from the list. If you've got
    fonts that aren't in the list that you'd like to be used,
    add their names and they'll be in the rotation.
*/

var fonts = [
    // Default Windows fonts
    "Meiryo, メイリオ",
    "MS PGothic, ＭＳ Ｐゴシック, MS Gothic, ＭＳ ゴック",
    "MS PMincho, ＭＳ Ｐ明朝, MS Mincho, ＭＳ 明朝",
    "Yu Gothic, YuGothic",
    "Yu Mincho, YuMincho",
    
    // Default OS X fonts
    "Hiragino Kaku Gothic Pro, ヒラギノ角ゴ Pro W3",
    "Hiragino Maru Gothic Pro, ヒラギノ丸ゴ Pro W3",
    "Hiragino Mincho Pro, ヒラギノ明朝 Pro W3",
    
    // Common Linux fonts
    "Takao Gothic, TakaoGothic",
    "Takao Mincho, TakaoMincho",
    "Sazanami Gothic",
    "Sazanami Mincho",
    "Kochi Gothic",
    "Kochi Mincho",
    "Dejima Mincho",
    "Ume Gothic",
    "Ume Mincho",
    
    // Other Japanese fonts people use.
    // You might want to try some of these!
    "EPSON 行書体Ｍ",
    "EPSON 正楷書体Ｍ",
    "EPSON 教科書体Ｍ",
    "EPSON 太明朝体Ｂ",
    "EPSON 太行書体Ｂ",
    "EPSON 丸ゴシック体Ｍ",
    "cinecaption",
    "nagayama_kai",
    "A-OTF Shin Maru Go Pro",
    "Hosofuwafont",
    "ChihayaGothic",
    "'chifont+', chifont",
    "darts font",
    "santyoume-font",
    "FC-Flower",
    "ArmedBanana", // This one is completely absurd. I recommend it.
    "HakusyuKaisyoExtraBold_kk",
    "aoyagireisyosimo2, AoyagiKouzanFont2OTF",
    "aquafont",
    
    // Add your fonts here!
    "Fake font name that you can change",
    "Another fake font name",
    "Just add them like this!",
    "Quotes around the name, comma after."
];

var existingFonts = [];
for (var i = 0; i < fonts.length; i++) {
    var fontName = fonts[i];
    if (fontExists(fontName)) {
        existingFonts.push(fontName);
    }
}

function fontExists(fontName) {
    // Approach from kirupa.com/html5/detect_whether_font_is_installed.htm - thanks!
    // Will return false for the browser's default monospace font, sadly.
    var canvas = document.createElement('canvas');
    var context = canvas.getContext("2d");
    var text = "wim-—l~ツ亻".repeat(100); // Characters with widths that often vary between fonts.
    
    context.font = "72px monospace";
    var defaultWidth = context.measureText(text).width;
    
    context.font = "72px " + fontName + ", monospace";
    var testWidth = context.measureText(text).width;
    
    return testWidth != defaultWidth;
}

function canRepresentGlyphs(fontName, glyphs) {
    var canvas = document.createElement('canvas');
    canvas.width = 50;
    canvas.height = 50;
    var context = canvas.getContext("2d");
    context.textBaseline = 'top';

    var blank = document.createElement('canvas');
    blank.width = canvas.width;
    blank.height = canvas.height;
    var blankDataUrl = blank.toDataURL();
    
    context.font = "24px " + fontName;
    
    var result = true;
    for (var i = 0; i < glyphs.length; i++) {
        context.fillText(glyphs[i], 0, 0);
        if (canvas.toDataURL() === blankDataUrl) {
            result = false;
            break;
        }
        context.clearRect(0, 0, canvas.width, canvas.height);
    }
    
    return result;
}

function shuffle(arr) {
    // WaniKani Reorder Ultimate overwrites Math.random(!?), so this
    // next line is required for Jitai to work in conjunction with it.
    var random = Math.randomB || Math.random;
    for (var i = arr.length; i > 0;) {
        var otherIndex = Math.floor(random() * i);
        i--;
        
        var temp = arr[i];
        arr[i] = arr[otherIndex];
        arr[otherIndex] = temp;
    }
    return arr;
}

var jitai = {
    setToRandomFont: function(glyphs) {
        // The font is set as a randomly shuffled list of the existing fonts
        // in order to always show a random font, even if the first one chosen
        // doesn't have a certain glyph being attempted to be displayed.
        var randomlyOrdered = shuffle(existingFonts.slice());
        
        // Some fonts don't contain certain radicals, for example, so it's best
        // to check that the font used can represent all the glyphs. The reason
        // the browser can't switch automatically is that some fonts report that
        // they have a glyph, when in fact they just show up blank.
        var currentFont;
        if (glyphs) {
            for (var i = 0; i < randomlyOrdered.length; i++) {
                var fontName = randomlyOrdered[i];
                if (canRepresentGlyphs(fontName, glyphs)) {
                    currentFont = fontName;
                    break;
                }
            }
        } else {
            currentFont = randomlyOrdered.join(', ');
        }
        
        this.currentFont = currentFont;
        
        jitai.setHoverFont(jitai.defaultFont);
        this.$characterSpan.css('font-family', currentFont);
    },
    
    setToDefaultFont: function(fontName) {
        jitai.setHoverFont(jitai.currentFont);
        this.$characterSpan.css('font-family', '');
    },
    
    setHoverFont: function(fontName) {
        this.$hoverStyle.text("#character span:hover {font-family: " + fontName + " !important;}");
    },
    
    init: function() {      
        this.$characterSpan = $('#character span');
        this.defaultFont = this.$characterSpan.css('font-family');
        
        this.$hoverStyle = $('<style/>', {'type': 'text/css'});
        $('head').append(this.$hoverStyle);
        
        // answerChecker.evaluate is only called when checking the answer, which
        // is why we catch it, check for the "proceed to correct/incorrect display"
        // condition, and set the font back to default if it's a non-stopping answer.
        var oldEvaluate = answerChecker.evaluate;
        answerChecker.evaluate = function(questionType, answer) {
            var result = oldEvaluate.apply(this, [questionType, answer]);
            
            if (!result.exception) {
                jitai.setToDefaultFont();
            }
            
            return result;
        };
        
        // $.jStorage.set('currentItem') is only called right when switching to a
        // new question, which is why we hook into it to randomize the font at the
        // exact right time: when a new item shows up.
        var oldSet = $.jStorage.set;
        $.jStorage.set = function(key, value, options) {
            var ret = oldSet.apply(this, [key, value, options]);
            
            if (key === 'currentItem') {
                jitai.setToRandomFont(value.kan || value.voc || value.rad);
            }
            
            return ret;
        };
    }
};

jitai.init();
