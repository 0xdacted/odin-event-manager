require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


def time_targeting(regdate)
  year_string = regdate.split('/')[2][0..1].to_s.prepend('20')
  year = year_string.to_i
  month = regdate.split('/')[0]
  day = regdate.split('/')[1]
  hour = regdate.split('/')[2].tr(':', ' ')[3..4]
  minutes = regdate.split('/')[2][6..7]

  t = Time.new(year, month, day, hour, minutes)

  puts t.strftime('this person registered at %H hours')
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_home_phone(home_phone)
  home_phone = home_phone.to_s.tr('-', '').tr(' ', '').tr('(', '').tr(')', '').tr('.', '')
  case
  when home_phone.length < 10 || home_phone.length > 11
    home_phone = '0000000000'

  when home_phone.length == 10
    home_phone

  when home_phone.length == 11 && home_phone[0] == 1
    home_phone = home_phone[1..10]

  when home_phone.length == 11 && home_phone[0] != 1
    home_phone = '0000000000'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  puts home_phone = clean_home_phone(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  puts time = time_targeting(row[:regdate])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
