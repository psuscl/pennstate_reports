class DigitalObjectsReport < AbstractReport

  register_report

  def query_string
    "select
      digital_object.id as id,
      digital_object.title as title,
      digital_object.publish as published,
      digital_object.digital_object_id as identifier,
      archival_object.id as archival_object_id,
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

  def construct_uris(row)
    row[:uri] = "/repositories/#{db.literal(@repo_id)}/digital_objects/#{row[:id]}"
    row.delete(:id)
    row[:archival_object_uri] = "/repositories/#{db.literal(@repo_id)}/archival_objects/#{row[:archival_object_id]}"
    row.delete(:archival_object_id)
  end
    
  def fix_row(row)
    ReportUtils.fix_boolean_fields(row, [:published, :file_version_published])
    ReportUtils.get_enum_values(row, [:object_type])
    ReportUtils.fix_identifier_format(row, :resource_identifier) if row[:resource_identifier]
    row[:top_container] = LinkedTopContainerSubreport.new(self, row[:archival_object_id]).get_content
    construct_uris(row)
    row.delete(:id)
    row.delete(:archival_object_id)
  end

  def page_break
    false
  end

  def identifier_field
    :record_title
  end
end

class LinkedTopContainerSubreport < AbstractSubreport

  register_subreport('top_container', ['archival_object'])

  def initialize(parent_report, archival_object_id)
    super(parent_report)
    @archival_object_id = archival_object_id
  end

  def query_string
    "select
      top_container.type_id as top_container_type,
      top_container.indicator as indicator
    from archival_object
        
      left outer join instance
        on instance.archival_object_id = archival_object.id
      
      left outer join sub_container
        on sub_container.instance_id = instance.id
      
      left outer join top_container_link_rlshp
        on top_container_link_rlshp.sub_container_id = sub_container.id
      
      left outer join top_container
        on top_container.id = top_container_link_rlshp.top_container_id
        
    where archival_object.id = #{db.literal(@archival_object_id)}
        and top_container.type_id is not null"

  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:top_container_type])
    row[:name] = "#{row[:top_container_type]} #{row[:indicator]}"
    row.delete(:top_container_type)
    row.delete(:indicator)
  end

  def self.field_name
    'name'
  end
end



