import python_terraform 
import github_action_utils as gha_utils
import os

def main():
  # Create tfvars variable with secrets
  tfvars = {'pve_api_url': os.environ["pve_api_url"], "pve_api_user": os.environ["pve_api_user"], "pve_api_password": os.environ["pve_api_password"], "vm_ssh_user": os.environ["vm_ssh_user"], "vm_ssh_password": os.environ["vm_ssh_password"], "pve_api_tls_verify": os.environ["pve_api_tls_verify"]}
  
  # Initialize the Terraform working directory
  global tf
  tf = python_terraform.Terraform(working_dir='.', variables=tfvars) #, terraform_bin_path='/home/runner/k8s')
  tf.init()

  # Run terraform Apply and Terraform Destroy
  list_ips=run_terraform()
  ping_vms(list_ips)

def run_terraform(): 
  # Plan the infrastructure changes
  tf.plan(capture_output=False)

  # Apply the infrastructure changes
  tf.apply(skip_plan=True, capture_output=False)
  str_output = tf.output()
  gha_utils.append_job_summary("Results after apply:")
  list_ips=str_output['ip']['value']

  # Writes ip's of created vms in output.txt
  f = open("output.txt", "a")
  gha_utils.append_job_summary("Created VM's:")
  for ip in list_ips: 
    gha_utils.append_job_summary("- " + ip)
    f.write(f'{ip}\n')
  f.close()

  return list_ips

def ping_vms(list_ips):
  list_responses = []
  for ip in list_ips:
    response = os.popen(f"ping -c 4 {ip} ").read()
    print(response)
    if ("Request timed out." and "unreachable") not in response:
      list_responses = list_responses + [ip]
  
  if not (list_ips == list_responses):
    s = set(list_responses)
    list_nonActive = [x for x in list_ips if x not in s]
    gha_utils.error("The following vm's are non-responsive: " + str(list_nonActive), title="Error Title")
    assert False

if __name__ == '__main__':
  main()
