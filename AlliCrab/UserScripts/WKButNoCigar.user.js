// ==UserScript==
// @name         WK But No Cigar
// @namespace    http*//www.wanikani.com/review/session
// @version      0.9
// @description  Stops Wanikani from marking answers that are 'a bit off' as correct, makes you try again until you are right or wrong.
// @author       Ethan
// @include        http*://www.wanikani.com/review/session*
// @include        http*://www.wanikani.com/lesson/session*
// @grant        none
// ==/UserScript==

var nocigar = {
    logMutations: function () {
        var alertText = "Close, but no cigar! Please try again";

        var observer = new MutationObserver(function (mutations) {
            // iterate over mutations..
            mutations.forEach(function (mutation) {
                if (mutation.addedNodes.length>0){
                    if(mutation.addedNodes.item(0).classList){
                        if(mutation.addedNodes.item(0).classList.contains("answer-exception-form")){
                            mutation.addedNodes.item(0).innerHTML=mutation.addedNodes.item(0).innerHTML.replace(/WaniKani is looking for the [a-zA-Z']+ reading/, alertText);
                            observer.disconnect();
                        }
                    }
                }
            });
                           
            var highLanders = document.querySelectorAll("#answer-exception");
            if (highLanders.length > 1){ // There can be only one!!!
                for (hL=1; hL<highLanders.length; hL++){
                    highLanders[hL].parentNode.removeChild(highLanders[hL])
                }
            }
        });
        
        var settings = {
            childList: true, subtree: true, attributes: false, characterData: false
        }
        
        observer.observe(document.body, settings);
    },
    doit: function () {
        
        console.log("doit");
        
        answerChecker.oldEvaluate = answerChecker.evaluate;
        
        //stops the code from submitting the answer
        console.log("wrap answerChecker");
        answerChecker.evaluate = function(e,t){
            result = answerChecker.oldEvaluate(e,t);
            if (result.passed === !0 && result.accurate === !1){
                result.exception = !0;
                
                nocigar.logMutations();
                
            }
            return result;
        };
        
    }
    
}

nocigar.doit();
