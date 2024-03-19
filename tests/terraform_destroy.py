import python_terraform 
import github_action_utils as gha_utils
import os

def main():
  tfvars = {'pve_api_url': os.environ["pve_api_url"], "pve_api_user": os.environ["pve_api_user"], "pve_api_password": os.environ["pve_api_password"], "vm_ssh_user": os.environ["vm_ssh_user"], "vm_ssh_password": os.environ["vm_ssh_password"], "pve_api_tls_verify": os.environ["pve_api_tls_verify"]}

  # Initialize the Terraform working directory
  global tf
  tf = python_terraform.Terraform(working_dir='.', variables=tfvars)
  tf.init()

  run_terraform()

def run_terraform(): 
  # Destroys created vms
  results = tf.destroy(force=None, auto_approve=True)
  print("Destroy Results:")
  print(results[1])
  gha_utils.append_job_summary("Results after destroy: " + str(results[1]).splitlines()[-1])

if __name__ == '__main__':
  main()
