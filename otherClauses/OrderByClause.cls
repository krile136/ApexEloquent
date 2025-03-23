public with sharing class OrderByClause {
  private Set<String> ORDERS = new Set<String>{'ASC', 'DESC'};
  private Set<String> NULLS_OPERATORS = new Set<String>{'FIRST', 'LAST'};

  private final List<String> fields;
  private final String order;
  private final String nullsOperator;
  
  public OrderByClause(String field) {
    this.fields = new List<String>{ field };
    this.order = 'ASC';
    this.nullsOperator = null;
  }

  public OrderByClause(String field, String order) {
    this.fields = new List<String>{ field };
    this.order = this.ORDERS.contains(order) ? order : 'ASC';
    this.nullsOperator = null;
  }

  public OrderByClause(String field, String order, String nullsOperator) {
    this.fields = new List<String>{ field };
    this.order = this.ORDERS.contains(order) ? order : 'ASC';
    this.nullsOperator = this.NULLS_OPERATORS.contains(nullsOperator) ? nullsOperator : null;
  }

  public OrderByClause(List<String> fields) {
    this.fields = fields;
    this.order = 'ASC';
    this.nullsOperator = null;
  }

  public OrderByClause(List<String> fields, String order) {
    this.fields = fields;
    this.order = this.ORDERS.contains(order) ? order : 'ASC';
    this.nullsOperator = null;
  }

  public OrderByClause(List<String> fields, String order, String nullsOperator) {
    this.fields = fields;
    this.order = this.ORDERS.contains(order) ? order : 'ASC';
    this.nullsOperator = this.NULLS_OPERATORS.contains(nullsOperator) ? nullsOperator : null;
  }

  public String build() {
    String orderBy = 'ORDER BY ' + String.join(this.fields, ', ') + ' ' + this.order;
    if (this.nullsOperator != null) {
      orderBy += ' NULLS ' + this.nullsOperator;
    }
    return orderBy;
  }
}
