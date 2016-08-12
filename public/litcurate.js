function reset_all(){
  $("#documents").empty();
  $("#axis").empty();
  $("#annotations").empty();
}

function load_documents(folder){
  $.ajax({
    url: "/load_documents",
    data: { folder: folder },
    success: function(data, status, params){
      $.each(data, function(index, val){
        console.log(val);
        var author = val["authors"][0]["last_name"];
        var year = val["year"];
        $("#documents").append('<li class="btn btn-default btn-sm">'+author+", "+year+"</li>");
      });
    }
  });
}

$(function(){
  $("#folders").change(function(data){
    //alert("folder selected");
    reset_all();
    console.log(data);
    var elem = $("#folders option:selected");
    var id = elem.val();
    var label = elem.text();
    $("#documents").append('<span class="glyphicon glyphicon-refresh glyphicon-refresh-animate"></span>">');
    load_documents(id);
    //alert(id);
    //alert(label);
  });
});
