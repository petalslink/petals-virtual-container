To create a new graph, follow these steps:
- Launch the Roboconf application 'Cacti'
- Through the web UI of Cacti:
 - Write your graph stuff:
   - create your Data Query or the Input Method,
   - create your Data Template,
   - create your Graph Template,
   - if needed associate your data query to the Host template ``Petals container host``
   - associate your Graph Template to the Host template ``Petals container host``
 - Once you graph is right (you can test it using existing host):
   - export the Host Template ``Petals container host`` with its dependencies,
   - and put this file to replace ``src/main/model/graph/Cacti/files/imports/cacti_host_template_petals_container_host.xml``
   - if a Data Query is needed, add your data query XML file somewhere under ``src/main/model/graph/Cacti/files/script_queries``
   - update installation scripts updating ``src/main/model/graph/Cacti/scripts/functions.sh``:
     - update function ``create_all_graphs_for_one_container`` adding a call to the function creating your new graph,
     - update function ``update_all_graphs_for_one_container`` adding a call to the function creating your new graph if your new graph depends on remote container,
