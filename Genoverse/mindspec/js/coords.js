function setStart(val){
    $("body").data("browse_start", val);
}
function setEnd(val){
    $("body").data("browse_end", val);
}
function setChr(val){
    $("body").data("browse_chr", val);
        <?php set_chr(val); ?>;
}
function getStart(){
    return $("body").data("browse_start");
}
function getEnd(){
    return $("body").data("browse_end");
}
function getChr(){
    return $("body").data("browse_chr");
}
