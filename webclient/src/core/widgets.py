from typing import Callable, Dict, List, Any, Union
from flask import url_for
from flask_wtf import FlaskForm


ARGUMENT_ERROR_MSG = "No value for argument '%s' was provided."


class FormLabels(object):
    """An object that contains methods to get labels from a model form."""

    def __init__(self, form: FlaskForm):
        if not form:
            raise ValueError(ARGUMENT_ERROR_MSG % "form")
        self.form = form

    def getAll(self) -> Dict[str, str]:
        """Returns a dict that contains the labels of all fields as values and the names as keys"""
        return self.getInList()

    def getInList(self, fieldNames: List[str]=None) -> Dict[str, str]:
        """Returns a dict that contains the labels of the fields with the provided names as values 
           and the names as keys"""
        if not fieldNames:
            fieldNames = self.form._fields.keys()
        return {name: self.form[name].label.text for name in fieldNames if name in self.form}

    def get(self, fieldName: str) -> str:
        """Returns the label of the field with the provided name"""
        if not fieldName:
            raise ValueError(ARGUMENT_ERROR_MSG % "fieldName")
        return self.form[fieldName].label.text


class WidgetContext(object):
    """A base object that contains operation template parameters and methods to build them.

    Attributes:
      title:            Title of the operation.
      model_name:       The name of the model in lowercase.
      form:             A model form object. Use to render labels and fields.
      fields:           List of field names to show in widget.
      render_binding:   A callable for custom rendering of fields.
      value_bindings:   List of functions for custom rendering of fields values.
    """
    def __init__(self, title: str, model_name: str, form: FlaskForm, fields: List[str], 
                 render_binding: Callable[[str], Union[None, bool]]=None, 
                 value_bindings: Dict[str, Callable[[Any], Any]]=None):
        if not title:
            raise ValueError(ARGUMENT_ERROR_MSG % "title")

        if not model_name:
            raise ValueError(ARGUMENT_ERROR_MSG % "model_name")

        if form is None:
            raise ValueError(ARGUMENT_ERROR_MSG % "form")

        all_fields = form._fields.keys()

        if not fields:
            # All fields are shown
            fields = all_fields

        self.title = title
        self.model_name = model_name.lower()
        self.form = form
        self.fields = fields
        self.render_binding = render_binding
        self.value_bindings = value_bindings
        self.labels = FormLabels(self.form).getInList(self.fields)
        self.all_fields = all_fields
    
    def getUrl(self, endpoint: str, values: Dict[str, Any]=None) -> str:
        if not endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "endpoint")
        if not values:
            return url_for(endpoint)
        else:
            return url_for(endpoint, **values)
    
    def getUrls(self, objs: Union[Dict, object], endpoint: str, values: Dict[str, Any]=None) -> List[str]:
        if not endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "endpoint")
        urls = []
        values = values if values else {}
        for obj in objs:
            values.update({"id": obj.id})
            urls.append(self.getUrl(endpoint, values))
        return urls
    
    def getValue(self, fieldName: str, value: Any) -> Any:
        value_binding = self.value_bindings[fieldName] if self.value_bindings and fieldName in self.value_bindings else None
        if value_binding is None or not callable(value_binding):
            return value
        else:
            return self.value_bindings[fieldName](value)
        
    def is_field_hidden(self, fieldName):
        return not self.render_binding is None and self.render_binding(fieldName) is None
        
    def is_field_disabled(self, fieldName):
        return not self.render_binding is None and self.render_binding(fieldName) is False


class ListWidgetContext(WidgetContext):
    """An object that contains the list widget parameters and methods to build them.

    Attributes:
      title:                        Title of the list.
      model_name:                   The name of the model in lowercase.
      form                          A model form object.
      fields:                       The list of names for fields to be shown as columns.
      objs:                         The list of records to show in the list.
      create_button_title:          The title of the button for create a new record operation.
      create_url_endpoint:          The endpoint for create url.
      create_url_values:            The dict of values for create url.
      retrieve_url_endpoint:        The endpoint for retrieve url. 
      retrieve_url_values:          The dict of values for retrieve url.
      delete_button_title:          The title of the button for delete a record operation.
      delete_url_endpoint:          The endpoint for delete url. 
      delete_url_values:            The dict of values for delete url. 
      empty_list_msg:               The message to show when the list is empty.
      delete_dialog_title:          The title of the delete confirmation dialog.
      delete_dialog_msg:            The message of the delete confirmation dialog. Must contain a 
                                    parameter for record name.
      delete_dialog_submit_title:   The title of the submit button from delete confirmation dialog
      delete_dialog_cancel_title:   The title of the cancel button from delete confirmation dialog
      render_binding:               A callable for custom rendering of fields.
      value_bindings:               List of functions for custom rendering of fields values.
    """
    def __init__(self, title: str, model_name: str, form: FlaskForm, fields: List[str], 
                 objs: List[Union[Dict, object]], create_button_title: str, create_url_endpoint: str, 
                 create_url_values: Dict[str, Any], retrieve_url_endpoint: str, 
                 retrieve_url_values: Dict[str, Any], delete_button_title: str, 
                 delete_url_endpoint: str, delete_url_values: Dict[str, Any], empty_list_msg: str, 
                 delete_dialog_title: str, delete_dialog_msg: str, delete_dialog_submit_title: str, 
                 delete_dialog_cancel_title: str, 
                 render_binding: Callable[[str], Union[None, bool]]=None, 
                 value_bindings: Dict[str, Callable[[Any], Any]]=None):
        super().__init__(title, model_name, form, fields, render_binding, value_bindings)
        if objs is None:
            raise ValueError(ARGUMENT_ERROR_MSG % "objs")

        if not create_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "create_url_endpoint")

        if not retrieve_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "retrieve_url_endpoint")

        if not delete_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "delete_url_endpoint")

        self.objs = objs
        self.create_button_title = create_button_title if create_button_title else "Add new"
        self.create_url_endpoint = create_url_endpoint
        self.create_url_values = create_url_values if not create_url_values is None else {}
        self.retrieve_url_endpoint = retrieve_url_endpoint
        self.retrieve_url_values = retrieve_url_values if not retrieve_url_values is None else {}
        self.delete_button_title = delete_button_title if delete_button_title else "Remove"
        self.delete_url_endpoint = delete_url_endpoint
        self.delete_url_values = delete_url_values if not delete_url_values is None else {}
        self.empty_list_msg = empty_list_msg if empty_list_msg else "No records found"
        self.delete_dialog_title = delete_dialog_title if delete_dialog_title else "Remove"
        self.delete_dialog_msg = delete_dialog_msg if delete_dialog_msg else "Do you want to remove <em>%s</em> record?"
        self.delete_dialog_submit_title = delete_dialog_submit_title if delete_dialog_submit_title else "Remove"
        self.delete_dialog_cancel_title = delete_dialog_cancel_title if delete_dialog_cancel_title else "Cancel"

        self.create_url = self.getUrl(self.create_url_endpoint, self.create_url_values)
        self.retrieve_urls = self.getUrls(self.objs, self.retrieve_url_endpoint, self.retrieve_url_values)
        self.delete_urls = self.getUrls(self.objs, self.delete_url_endpoint, self.delete_url_values)
    
    def getValue(self, obj: Union[Dict, object], fieldName: str):
        if isinstance(obj, dict):
            return super().getValue(fieldName, obj[fieldName])
        else:
            return super().getValue(fieldName, obj.__getattribute__(fieldName))
    

class RetrieveWidgetContext(WidgetContext):
    """An object that contains the retrieve widget parameters and methods to build them.

    Attributes:
      title:                        Title of the list.
      model_name:                   The name of the model in lowercase.
      form                          A model form object.
      fields:                       The list of names for fields to be shown as columns.
      close_button_title:           The title of the button for return to list.
      close_url_endpoint:           The endpoint for close url.
      close_url_values:             The dict of values for close url.
      delete_button_title:          The title of the button for delete a record operation.
      delete_url_endpoint:          The endpoint for delete url. 
      delete_url_values:            The dict of values for delete url. 
      update_button_title:          The title of the button for update a record operation.
      update_url_endpoint:          The endpoint for update url.
      update_url_values:            The dict of values for update url.
      retrieve_url_endpoint:        The endpoint for retrieve url. 
      retrieve_url_values:          The dict of values for retrieve url.
      delete_dialog_title:          The title of the delete confirmation dialog.
      delete_dialog_msg:            The message of the delete confirmation dialog. Must contain a 
                                    parameter for record name.
      delete_dialog_submit_title:   The title of the submit button from delete confirmation dialog
      delete_dialog_cancel_title:   The title of the cancel button from delete confirmation dialog
      render_binding:               A callable for custom rendering of fields.
      value_bindings:               List of functions for custom rendering of fields values.
    """
    def __init__(self, title: str, model_name: str, form: FlaskForm, fields: List[str],  
                 close_button_title: str, close_url_endpoint: str, close_url_values: Dict[str, Any], 
                 delete_button_title: str, delete_url_endpoint: str, delete_url_values: Dict[str, Any], 
                 update_button_title: str, update_url_endpoint: str, update_url_values: Dict[str, Any], 
                 retrieve_url_endpoint: str, retrieve_url_values: Dict[str, Any],  
                 delete_dialog_title: str, delete_dialog_msg: str, delete_dialog_submit_title: str, 
                 delete_dialog_cancel_title: str, 
                 render_binding: Callable[[str], Union[None, bool]]=None, 
                 value_bindings: Dict[str, Callable[[Any], Any]]=None):
        super().__init__(title, model_name, form, fields, render_binding, value_bindings)
        if not close_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "close_url_endpoint")

        if not delete_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "delete_url_endpoint")

        if not update_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "update_url_endpoint")

        if not retrieve_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "retrieve_url_endpoint")

        self.close_button_title = close_button_title if close_button_title else "Go to list"
        self.close_url_endpoint = close_url_endpoint
        self.close_url_values = close_url_values if not close_url_values is None else {}
        self.delete_button_title = delete_button_title if delete_button_title else "Remove"
        self.delete_url_endpoint = delete_url_endpoint
        self.delete_url_values = delete_url_values if not delete_url_values is None else {}
        self.update_button_title = update_button_title if update_button_title else "Edit"
        self.update_url_endpoint = update_url_endpoint
        self.update_url_values = update_url_values if not update_url_values is None else {}
        self.retrieve_url_endpoint = retrieve_url_endpoint
        self.retrieve_url_values = retrieve_url_values if not retrieve_url_values is None else {}
        self.delete_dialog_title = delete_dialog_title if delete_dialog_title else "Remove"
        self.delete_dialog_msg = delete_dialog_msg if delete_dialog_msg else "Do you want to remove this record?"
        self.delete_dialog_submit_title = delete_dialog_submit_title if delete_dialog_submit_title else "Remove"
        self.delete_dialog_cancel_title = delete_dialog_cancel_title if delete_dialog_cancel_title else "Cancel"

        self.delete_url_values.update({"id": self.form.id.data})
        self.update_url_values.update({"id": self.form.id.data})
        self.retrieve_url_values.update({"id": self.form.id.data})

        self.close_url = self.getUrl(self.close_url_endpoint, self.close_url_values)
        self.delete_url = self.getUrl(self.delete_url_endpoint, self.delete_url_values)
        self.update_url = self.getUrl(self.update_url_endpoint, self.update_url_values)
        self.retrieve_url = self.getUrl(self.retrieve_url_endpoint, self.retrieve_url_values)


class UpdateWidgetContext(WidgetContext):
    """An object that contains the update widget parameters and methods to build them.

    Attributes:
      title:                        Title of the list.
      model_name:                   The name of the model in lowercase.
      form                          A model form object.
      fields:                       The list of names for fields to be shown as columns.
      close_button_title:           The title of the button for discard changes.
      close_url_endpoint:           The endpoint for close url.
      close_url_values:             The dict of values for close url.
      update_button_title:          The title of the button for update a record operation.
      update_url_endpoint:          The endpoint for update url.
      update_url_values:            The dict of values for update url.
      render_binding:               A callable for custom rendering of fields.
      value_bindings:               List of functions for custom rendering of fields values.
    """
    def __init__(self, title: str, model_name: str, form: FlaskForm, fields: List[str],  
                 close_button_title: str, close_url_endpoint: str, close_url_values: Dict[str, Any], 
                 update_button_title: str, update_url_endpoint: str, update_url_values: Dict[str, Any], 
                 render_binding: Callable[[str], Union[None, bool]]=None, 
                 value_bindings: Dict[str, Callable[[Any], Any]]=None):
        super().__init__(title, model_name, form, fields, render_binding, value_bindings)
        if not close_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "close_url_endpoint")

        if not update_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "update_url_endpoint")

        self.close_button_title = close_button_title if close_button_title else "Go to list"
        self.close_url_endpoint = close_url_endpoint
        self.close_url_values = close_url_values if not close_url_values is None else {}
        self.update_button_title = update_button_title if update_button_title else "Update"
        self.update_url_endpoint = update_url_endpoint
        self.update_url_values = update_url_values if not update_url_values is None else {}

        self.close_url_values.update({"id": self.form.id.data})
        self.update_url_values.update({"id": self.form.id.data})

        self.close_url = self.getUrl(self.close_url_endpoint, self.close_url_values)
        self.update_url = self.getUrl(self.update_url_endpoint, self.update_url_values)


class CreateWidgetContext(WidgetContext):
    """An object that contains the create widget parameters and methods to build them.

    Attributes:
      title:                        Title of the list.
      model_name:                   The name of the model in lowercase.
      form                          A model form object.
      fields:                       The list of names for fields to be shown as columns.
      close_button_title:           The title of the button for return to list.
      close_url_endpoint:           The endpoint for close url.
      close_url_values:             The dict of values for close url.
      create_button_title:          The title of the button for create a record operation.
      create_url_endpoint:          The endpoint for create url.
      create_url_values:            The dict of values for create url.
      render_binding:               A callable for custom rendering of fields.
      value_bindings:               List of functions for custom rendering of fields values.
    """
    def __init__(self, title: str, model_name: str, form: FlaskForm, fields: List[str],  
                 close_button_title: str, close_url_endpoint: str, close_url_values: Dict[str, Any], 
                 create_button_title: str, create_url_endpoint: str, create_url_values: Dict[str, Any], 
                 render_binding: Callable[[str], Union[None, bool]]=None, 
                 value_bindings: Dict[str, Callable[[Any], Any]]=None):
        super().__init__(title, model_name, form, fields, render_binding, value_bindings)
        if not close_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "close_url_endpoint")

        if not create_url_endpoint:
            raise ValueError(ARGUMENT_ERROR_MSG % "update_url_endpoint")

        self.close_button_title = close_button_title if close_button_title else "Discard"
        self.close_url_endpoint = close_url_endpoint
        self.close_url_values = close_url_values if not close_url_values is None else {}
        self.create_button_title = create_button_title if create_button_title else "Create"
        self.create_url_endpoint = create_url_endpoint
        self.create_url_values = create_url_values if not create_url_values is None else {}

        self.create_url_values.update({"id": self.form.id.data})

        self.close_url = self.getUrl(self.close_url_endpoint, self.close_url_values)
        self.create_url = self.getUrl(self.create_url_endpoint, self.create_url_values)
