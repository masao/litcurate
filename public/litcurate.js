function reset_all(){
        $("#documents").clear();
        $("#axis").clear();
        $("#annotations").clear();
}

$.document.ready(function(){
        $("#folders").selected(function(){
                alert("folders selected");
        });
});
