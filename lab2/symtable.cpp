#include "symtable.hpp"
TSymbolTable *CreateUserVariableTable(TSymbolTable *parentTable) {
  TSymbolTable *table = NULL;
  try {
    table = new TSymbolTable;
  }
  catch (std::bad_alloc &ba) {
    return NULL;
  }
  table->parentTable = parentTable;
  table->isHidden = false;
  if (NULL != parentTable)
    parentTable->childTables.push_back(table);
  table->childTables.clear();
  table->data.clear();
  return table;
}

void DestroyUserVariableTable(TSymbolTable *table) {
  if (table == NULL)
    return;

  auto childTablesNumber = table->childTables.size();
  for (auto i = 0u; i < childTablesNumber; ++i) {
    DestroyUserVariableTable(table->childTables[i]);
  }
  table->childTables.clear();

  for (auto j = 0u; j < table->data.size(); ++j)
    delete table->data[j].name;
  table->data.clear();
  delete table;
  return;
}

bool HideUserVariableTable(TSymbolTable *table) {
  if (table == NULL)
    return false;
  table->isHidden = true;
  return true;
}
TSymbolTableElementPtr LookupUserVariableTable(TSymbolTable *table, std::string varName) {
  if (NULL == table || varName.empty() || table->data.empty() || table->isHidden) {
    return NULL;
  }

  for (auto i = 0u; i < table->data.size(); ++i) {
    if (varName == *table->data[i].name) {
      TSymbolTableElementPtr tableRow = NULL;
      try {
        tableRow = new TSymbolTableElement;
      }
      catch (std::bad_alloc &ba) {
        return NULL;
      }
      tableRow->table = table;
      tableRow->index = i;
      return tableRow;
    }
  }
  return NULL;
}

TSymbolTableElementPtr LookupUserVariableTableRecursive(TSymbolTable *table, std::string varName) {
  if (NULL == table || varName.empty() || table->isHidden) {
    return NULL;
  }

  for (auto i = 0u; i < table->data.size(); ++i) {
    if (varName == *table->data[i].name) {
      TSymbolTableElementPtr tableRow = NULL;
      try {
        tableRow = new (TSymbolTableElement);
      }
      catch (std::bad_alloc &ba) {
        return NULL;
      }
      tableRow->table = table;
      tableRow->index = i;
      return tableRow;
    }
  }
  return LookupUserVariableTableRecursive(table->parentTable, varName);
}

bool InsertUserVariableTable(TSymbolTable *table, std::string varName, SubexpressionValueTypeEnum type, TSymbolTableElementPtr &tableRow) {
  if (NULL == table || varName.empty() || table->isHidden) {
    return false;
  }
  TSymbolTableRecord newRecord;
  try {
    newRecord.name = new std::string(varName);
  }
  catch (std::bad_alloc &ba) {
    return false;
  }
  newRecord.valueType = type;
  table->data.push_back(newRecord);

  auto i = table->data.size() - 1;

  if (NULL == tableRow) {
    try {
      tableRow = new TSymbolTableElement;
    }
    catch (std::bad_alloc &ba) {
      return false;
    }

    tableRow->table = table;
    tableRow->index = i;
  }
  return true;
}
