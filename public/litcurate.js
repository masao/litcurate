function reset_all(){
  $("#documents").empty();
  $("#axis").empty();
  $("#annotations").empty();
}

function drag(event){
  console.log(event);
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
            $("#documents").append('<li draggable="true" ondragstart="drag(event)" id="'+data["id"]+'" class="btn btn-default btn-sm">'+author+", "+year+"</li>");
          }
        });
      });
      $("span.loading-documents").empty();
    }
  });
}

function load_annotations(folder){
  $.ajax({
    url: "/load_annotations",
    data: { folder: folder },
    success: function(data, status, params){
      console.log(data);
      $.each(data, function(index, val){
        $("#axis").append('<li id="annotation-'+val["id"]+'" class="annotation btn btn-default">'+val["name"]+"</li>");
      });
    }
  });
}

function new_annotation(){
  var folder = $("#folders option:selected").val();
  bootbox.dialog({
    title: "New annotation",
    message: '<div class="row">'+
      '<div class="col-md-12">'+
      '<form class="form-horizontal">'+
      '<input type="hidden" name="folder" id="folder" value="'+folder+'"/>'+
      '<div class="form-group">'+
      '<label class="col-md-4 control-label" for="name">Name</label>'+
      '<div class="col-md-4">'+
      '<input id="name" name="name" type="text" placeholder="Name" class="form-control input-md"/>'+
      '</div>'+
      '</div>'+
      '<div class="form-group">'+
      '<label class="col-md-4 control-label" for="items">Items</label>'+
      '<div class="col-md-4">'+
      '<input id="item-1" name="item-1" type="text" placeholder="Item 1" class="form-control input-md"/>'+
      '<input id="item-2" name="item-2" type="text" placeholder="Item 2" class="form-control input-md"/>'+
      '</div>'+
      '</div>'+
      '</form>'+
      '</div>'+
      '</div>',
    onEscape: true,
    backdrop: true,
    buttons: {
      success: {
        label: "Save",
        className: "btn-success",
        callback: function(){
          var name = $("#name").val();
          var folder = $("#folder").val();
          var items = [];
          for (var i = 1; i <= 10; i++) {
            var item = $("#item-"+i).val();
            if (!item) break;
            items.push(item);
          }
          console.log(name);
          console.log(folder);
          console.log(items);
          $.ajax({
            url: "/new_annotation",
            data: { name: name, folder: folder, item: items },
            method: "POST",
            success: function(){
              load_annotations(folder);
            }
          });
        }
      }
    }
  });
}

function load_annotation(annotation){
  $("#axis .annotation.btn-primary").removeClass("btn-primary");
  $(annotation).addClass("btn-primary");
  var annotation_id = annotation.id.replace(/^annotation-/, "");
  $.ajax({
    url: "/load_items",
    data: { annotation: annotation_id },
    success: function(){
      
    }
  });
}

$(function(){
  $("#folders").change(function(data){
    reset_all();
    //console.log(data);
    var elem = $("#folders option:selected");
    var id = elem.val();
    var label = elem.text();
    $("#documents").append('<span class="loading-documents"><i class="fa fa-spinner fa-spin fa-3x fa-fw"></i><span class="sr-only">Loading...</span></span>');
    load_documents(id);
    load_annotations(id);
  });
  $("#new_annotation").click(function(e){
    e.preventDefault();
    new_annotation();
  });
  $("#axis").on("click", ".annotation", function(e){
    //console.log(e);
    //console.log(e.target);
    load_annotation(e.target);
  });
});
