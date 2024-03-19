import yaml as yaml
import random
import string
from jinja2 import Environment, FileSystemLoader
import github_action_utils as gha_utils

def random_string_generation(length):
  # choose random lowercase letters for unique name
  letters = string.ascii_lowercase
  result_str = ''.join(random.choice(letters) for i in range(length))
  return result_str

def write_file(testVars, output_file_name):
  environment = Environment(loader=FileSystemLoader("tests/templates/"))
  template = environment.get_template("module.tpl")
  filename = "main.tf"
  content = template.render(
        name = output_file_name,
        vm_count = random.choice(testVars['vm_count']),
        vm_num_cpus = random.choice(testVars['vm_num_cpus']),
        pve_datastore = random.choice(testVars['pve_datastore']),
    )
  
  # Save template
  with open(filename, mode="w", encoding="utf-8") as message:
        message.write(content)
        print(f"... wrote {filename}")

def main():
  ### Generate Random String for VM name
  str_tfvarName = "pipeline-" + random_string_generation(length = 5)
  gha_utils.append_job_summary("Unique Name for VM's: " + str_tfvarName)
  
  ### Import Yaml file with all possible test values
  with open('tests/test_values.yaml', 'r') as file:
    testVars = yaml.safe_load(file)
  print(testVars)
  write_file(testVars, str_tfvarName)

if __name__ == '__main__':
  main()
