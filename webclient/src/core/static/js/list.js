function onRowClick (event) {
    id = event.target.id;
    if (id == undefined || 
        id.slice(0, 3) != 'td-' || 
        event.target.parentElement.tagName != 'TR') return;
    $("form#show-details-" + event.target.parentElement.id).submit();
}