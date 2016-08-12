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
        $.ajax({
          url: "/load_document",
          data: { id: val["id"] },
          success: function(data, status, params){
            console.log(data);
            var author = data["authors"][0]["last_name"];
            var year = data["year"];
            $("#documents").append('<li class="btn btn-default btn-sm">'+author+", "+year+"</li>");
          }
        });
      });
      $("span.loading-documents").empty();
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
    $("#documents").append('<span class="loading-documents"><i class="fa fa-spinner fa-spin fa-3x fa-fw"></i><span class="sr-only">Loading...</span></span>');
    load_documents(id);
  });
});
