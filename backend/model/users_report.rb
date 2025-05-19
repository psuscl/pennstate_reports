class UsersReport < AbstractReport

  register_report


  def query_string

    "SELECT
      id,
      username as identifier,
      name,
      department,
      title as user_title,
      email,
      telephone,
      source,
      is_system_user,
      is_hidden_user,
      is_active_user,
      group_list
    from user
    natural left outer join
    (select
      group_user.user_id as id,
      group_concat(`group`.description separator '; ') as group_list
      from group_user, `group`
      where `group`.id = group_user.group_id
      group by group_user.user_id
    ) as `groups`"
    
  end


  def fix_row(row)

    user_id = row[:id]
    nbsp = '   '

    if format == 'pdf' || format == 'html'
      row[:source] = row[:source] + nbsp * 12
      row[:source] = row[:source] + " SYSTEM_USER " + nbsp * 8 if row[:is_system_user] != 0
      row[:source] = row[:source] + " HIDDEN_USER " if row[:is_hidden_user] != 0
      row.delete(:is_system_user); row.delete(:is_hidden_user); row.delete(:id)
    else
      row[:title] = row[:user_title]
      row.delete(:user_title)  # as user_title, because title displays as "User Group Report" in HTML report
      ReportUtils.fix_boolean_fields(row, [:is_system_user, :is_hidden_user, :is_active_user])
    end

    puts row
  end


  def identifier_field
    :name
  end

  def page_break
    false
  end


  # these two go together because the base class and templates assume all reports are repository based.
  def repository
    "Global repository"
  end

  def after_tasks
    info.delete(:repository)
  end

end