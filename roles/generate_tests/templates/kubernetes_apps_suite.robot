*** Settings ***

Name            {{ generate_tests_kubernetes_apps_suite_name }}
Library         Azimuth
Library         Collections
Test Tags       {{ generate_tests_kubernetes_apps_default_test_tags | join("  ") }}
Test Timeout    {{ generate_tests_kubernetes_apps_default_test_timeout }}


*** Variables ***

${apps_cluster_name}  {{
    generate_tests_kubernetes_apps_k8s_name_prefix ~
    "-" ~
    lookup('community.general.random_string', length = 5, upper = false, special = false)
}}


*** Test Cases ***

Setup Apps Kubernetes Cluster
    [Tags]  appscluster  create
    [Timeout]  {{ generate_tests_kubernetes_apps_setup_timeout }}
{% if generate_tests_kubernetes_apps_k8s_template %}
    ${template} =  Fetch Kubernetes Cluster Template  {{ generate_tests_kubernetes_apps_k8s_template }}
{% else %}
    ${template} =  Find Latest Kubernetes Cluster Template
    ...  tags={{ generate_tests_kubernetes_apps_k8s_template_tags | to_json }}
{% endif %}
{% if generate_tests_kubernetes_apps_k8s_control_plane_size %}
    ${cp_size} =  Fetch Size  {{ generate_tests_kubernetes_apps_k8s_control_plane_size }}
{% else %}
    ${cp_size} =  Find Smallest Size With Resources  min_cpus=2  min_ram=4096  min_disk=20
{% endif %}
{% if generate_tests_kubernetes_apps_k8s_worker_size %}
    ${worker_size} =  Fetch Size  {{ generate_tests_kubernetes_apps_k8s_worker_size }}
{% else %}
    ${worker_size} =  Find Smallest Size With Resources  min_cpus=2  min_ram=4096  min_disk=20
{% endif %}
    ${config} =  New Kubernetes Config
    ...  name=${apps_cluster_name}
    ...  template=${template.id}
    ...  control_plane_size=${cp_size.id}
    ${config} =  Add Node Group To Kubernetes Config  ${config}
    ...  name=md-0
    ...  machine_size=${worker_size.id}
    ...  count={{ generate_tests_kubernetes_apps_k8s_worker_count }}
    ${cluster} =  Create Kubernetes Cluster  ${config}


Verify Apps Kubernetes Cluster
    [tags]  appscluster  verify
    [Timeout]  {{ generate_tests_kubernetes_apps_verify_timeout }}
    ${cluster} =  Find Kubernetes Cluster By Name  ${apps_cluster_name}
    ${cluster} =  Wait For Kubernetes Cluster Ready  ${cluster.id}

{% for test_case in generate_tests_kubernetes_apps_test_cases %}
{% include (test_case.template | default(generate_tests_kubernetes_apps_test_case_template, True)) %}


{% endfor %}

Teardown Apps Kubernetes Cluster
    [Tags]  appscluster  delete
    [Timeout]  {{ generate_tests_kubernetes_apps_teardown_timeout }}
    ${cluster} =  Find Kubernetes Cluster By Name  ${apps_cluster_name}
    Delete Kubernetes Cluster  ${cluster.id}
