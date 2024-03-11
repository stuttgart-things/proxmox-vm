import python_terraform 
import yaml
import random
import string
import pprint
import os
import json

### Control Booleans
cb_runApply = False
cb_runDestroy = False
cb_destroyOldMachines = False
cb_printTfvars = False
cb_omitTfLiveOutput = False
cb_printOutput = False
output_file_name = "vm_info.txt"

def main():
  # Initialize the Terraform working directory
  global tf
  tf = python_terraform.Terraform(working_dir='.')
  tf.init()


  dict_tfvars = get_test_tfvars()
  if os.path.isfile(output_file_name) & cb_destroyOldMachines: 
    if os.path.getsize(output_file_name) > 0:
      terraform_destroy(output_file_name)
    os.remove(output_file_name)
  str_tfOutput = run_terraform(tfvars=dict_tfvars)

  if (cb_printTfvars):
    print ("### TFVARS ###")
    pprint.pprint(dict_tfvars)
    print ("###############\n")

  if (cb_printOutput): 
    print(f"""
          ### TF OUTPUT ###
          {str_tfOutput}
          #################\n
          """)
  save_env_vars()

def random_string_generation(length):
  # choose from all lowercase letter
  letters = string.ascii_lowercase
  result_str = ''.join(random.choice(letters) for i in range(length))
  return result_str

def get_test_tfvars():
  ### Generate Random String for VM name
  str_tfvarName = "pipeline-" + random_string_generation(length = 5)
  
  ### Import Yaml file with all possible test values
  with open('test_values.yaml', 'r') as file:
    testVars = yaml.safe_load(file)
  
  ### Get random value for test tfvars
  int_tfvarVmCount, str_tfvarVmNumCpus, str_tfvarPveDatastore = random.choice(testVars['vm_count']), str(random.choice(testVars['vm_num_cpus'])), random.choice(testVars['pve_datastore'])
  
  ### Generate dictionary with test tfvars
  dict_tfvars = {'name': str_tfvarName, 'vm_count':int_tfvarVmCount, 'vm_num_cpus':str_tfvarVmNumCpus, 'pve_datastore':str_tfvarPveDatastore}
  return dict_tfvars

def run_terraform(tfvars): 
  # Plan the infrastructure changes
  tf.plan(capture_output=cb_omitTfLiveOutput, var=tfvars)
  
  if (cb_runApply):
    # Apply the changes
    tf.apply(skip_plan=True, capture_output=cb_omitTfLiveOutput, var=tfvars)
  
    # Get the output of the applied resources
    output = tf.output()

    # Save random tf_vars 
    f = open(output_file_name, "w")
    f.write(str(tfvars))
    f.close()
  else: 
    output = "Apply was deactivated"

  if (cb_runDestroy):
    terraform_destroy(output_file_name)
    os.remove(output_file_name)
  return output
  
def terraform_destroy(vm_info):  
  f = open(vm_info, "r")
  destroy_vars = eval(f.read())
  f.close() 

  tf.destroy(var=destroy_vars, force=None, auto_approve=True, capture_output=cb_omitTfLiveOutput)

def save_env_vars():
  #os.environ["ENV_VAR_PY"] = "Mundo"

  print("HOLA " +str(os.getenv('ENV_VAR_PY')))
  os.environ["ENV_VAR_PY"] = "Mundo"

if __name__ == '__main__':
  main()
