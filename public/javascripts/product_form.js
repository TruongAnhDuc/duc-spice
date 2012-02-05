function stopRKey(evt) {
    var evt = (evt) ? evt : ((event) ? event : null);
    var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
    if ((evt.keyCode == 13) && (node.type=="text"))  {
        return false;
    }
}

document.onkeypress = stopRKey;

function clearOrder(){
    qty_inps = $$('input.qty');
    for(var i=0; i < qty_inps.length; i++){
        var item = qty_inps[i];
        if (item.value != ""){
            item.value = "";
            item.onchange();
        }
    }
    return false;
}