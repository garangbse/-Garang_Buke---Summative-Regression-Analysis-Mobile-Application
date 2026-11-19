import 'package:earnings_predictor/models/input_field.dart';

// Allowed values of the categorical inputs. They are the labels used by the API.
const List<String> genderOptions = ['Female', 'Male'];

const List<String> educationOptions = [
  'Pre-primary',
  'Primary education',
  'Lower secondary education',
  'Upper secondary education',
  'Tertiary education',
  'Missing',
];

const List<String> occupationOptions = [
  'Managers',
  'Professionals',
  'Technicians_and_associate_professionals',
  'Clerical_support_workers',
  'Service_and_sales_workers',
  'Skilled_agricultural,_forestry_and_fishery workers',
  'Craft_and_related_trades_workers',
  'Plant_and_machine_operators_and_assemblers',
  'Elementary_occupations',
];

const List<String> industryOptions = ['Agriculture', 'Industry', 'Services'];

const List<String> sectorOptions = ['Formal sector', 'Informal Sector', 'Household'];

const List<String> contractOptions = [
  'Daily contract/Agreement',
  'Less than one month',
  'One to less than 3 months',
  '3 to less than 6 months',
  '6 to less than 12 months',
  '12 to less than 24 months',
  '2 years or more',
  'Missing',
];

const String _chooseHint = 'Type it, or tap the arrow to choose';

/// The page is built from these sections. There is exactly one text field per model input (10 in total).
const List<InputSection> inputSections = [
  InputSection(title: 'Personal details', fields: [
    InputField(key: 'a04', label: 'Age (years)', hint: 'Whole number from 18 to 35', numeric: true),
    InputField(key: 'a01', label: 'Gender', hint: _chooseHint, options: genderOptions),
    InputField(key: 'b02a', label: 'Education level', hint: _chooseHint, options: educationOptions),
  ]),
  InputSection(title: 'Job details', fields: [
    InputField(key: 'indd01', label: 'Occupation group', hint: _chooseHint, options: occupationOptions),
    InputField(key: 'main_sect', label: 'Industry', hint: _chooseHint, options: industryOptions),
    InputField(key: 'prod_unit', label: 'Employment sector', hint: _chooseHint, options: sectorOptions),
    InputField(key: 'd08', label: 'Contract duration', hint: _chooseHint, options: contractOptions),
  ]),
  InputSection(title: 'Working pattern', fields: [
    InputField(key: 'usual_h', label: 'Usual working hours per week', hint: 'Number from 1 to 120', numeric: true),
    InputField(key: 'd24', label: 'Work experience (years)', hint: 'Number from 0 to 25', numeric: true),
    InputField(key: 'd24b', label: 'Months worked per year', hint: 'Whole number from 1 to 12', numeric: true),
  ]),
];

/// All the inputs in one flat list (the order of the page).
final List<InputField> allInputFields = [
  for (final section in inputSections) ...section.fields,
];
