class TopContainersReport < AbstractReport

  register_report
  
  def query_string
    "select
      top_container.id as id,
      top_container.ils_holding_id as location_label,
      top_container.type_id as type,
      top_container.indicator as indicator,
      top_container.ils_holding_id as location_label,
      count(distinct collection.id) as resources,
      group_concat(distinct collection.resource_id SEPARATOR ';') as resource,
      count(archival_object.id) as items
    
    from top_container

      left outer join top_container_link_rlshp
        on top_container_link_rlshp.top_container_id = top_container.id
      
      left outer join sub_container
        on sub_container.id = top_container_link_rlshp.sub_container_id
      
      left outer join instance
        on instance.id = sub_container.instance_id
      
      left outer join archival_object
        on archival_object.id = instance.archival_object_id
      
      left outer join (select id, ead_id as resource_id, publish from resource) as collection
        on collection.id = archival_object.root_record_id
    
    where top_container.repo_id = #{db.literal(@repo_id)} and collection.publish
    group by top_container.id
    order by resources desc"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:type])
    ReportUtils.fix_container_indicator(row)
    row[:location] = LinkedLocationSubreport.new(self, row[:id]).get_content
    row[:uri] = "/repositories/#{db.literal(@repo_id)}/top_containers/#{row[:id]}"
    row.delete(:id)
  end

end

class LinkedLocationSubreport < AbstractSubreport

  register_subreport('location', ['top_container'])

  def initialize(parent_report, top_container_id)
    super(parent_report)
    @top_container_id = top_container_id
  end

  def query_string
    "select
      location.id as id,
      location.classification as location_class,
      location.coordinate_1_label,
      location.coordinate_1_indicator,
      location.coordinate_2_label,
      location.coordinate_2_indicator,
      location.coordinate_3_label,
      location.coordinate_3_indicator
    from location
      left outer join top_container_housed_at_rlshp
        on top_container_housed_at_rlshp.location_id = location.id
      left outer join top_container
        on top_container.id = top_container_housed_at_rlshp.top_container_id
    where top_container.id = #{db.literal(@top_container_id)}"
  end

  def fix_row(row)
    ReportUtils.get_location_coordinate(row)
    row[:location_uri] = "/locations/#{row[:id]}"
    row.delete(:id)
  end
end