class DigitalObjectsReport < AbstractReport

  register_report

  def query_string
    "select
      concat('/repositories/', digital_object.repo_id, '/digital_objects/', digital_object.id) as uri,
      digital_object.title as title,
      digital_object.publish as published,
      digital_object.digital_object_id as identifier,
      archival_object.id as archival_object_id,
      concat('/repositories/', archival_object.repo_id, '/archival_objects/', archival_object.id) as archival_object_uri,
      resource.title as resource_title,
      resource.identifier as resource_identifier,
      file_version.file_uri,
      file_version.publish as file_version_published,
      user_defined.enum_1_id as object_type
    from digital_object

      left outer join instance_do_link_rlshp
        on instance_do_link_rlshp.digital_object_id = digital_object.id

      left outer join instance
        on instance.id = instance_do_link_rlshp.instance_id

      left outer join archival_object
        on archival_object.id = instance.archival_object_id

      left outer join resource
        on resource.id = instance.resource_id
          or resource.id = archival_object.root_record_id
      
      left outer join file_version
        on file_version.digital_object_id = digital_object.id
      
      left outer join user_defined
        on user_defined.digital_object_id = digital_object.id
      
    where digital_object.repo_id = #{db.literal(@repo_id)}"
  end

  def fix_row(row)
    ReportUtils.fix_boolean_fields(row, [:published, :file_version_published])
    ReportUtils.get_enum_values(row, [:object_type])
    ReportUtils.fix_identifier_format(row, :resource_identifier) if row[:resource_identifier]
    row[:top_container] = LinkedTopContainerSubreport.new(self, row[:archival_object_id]).get_content
    row.delete(:archival_object_id)
  end

  def page_break
    false
  end

  def identifier_field
    :record_title
  end
end
