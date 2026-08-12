/**
 * Design system barrel.
 *
 * Application code imports from '@/design-system/ui', never from individual
 * files. Keeps the public surface of the design system explicit and makes it
 * obvious when something new is being added rather than composed.
 */
export { Button, buttonVariants, type ButtonProps } from './button';
export { Spinner } from './spinner';
export { Field, useField, useFieldControlProps, type FieldProps } from './field';
export { Input, type InputProps } from './input';
export { Textarea } from './textarea';
export {
  SelectRoot,
  SelectGroup,
  SelectValue,
  SelectTrigger,
  SelectContent,
  SelectItem,
} from './select';
export { Checkbox } from './checkbox';
export { RadioGroup, RadioItem } from './radio';
export { Switch } from './switch';
export { SearchInput, type SearchInputProps } from './search-input';
export { DatePicker, type DatePickerProps } from './date-picker';
export {
  Dialog,
  DialogTrigger,
  DialogClose,
  DialogContent,
  DialogHeader,
  DialogFooter,
  DialogTitle,
  DialogDescription,
} from './dialog';
export {
  Drawer,
  DrawerTrigger,
  DrawerClose,
  DrawerContent,
  DrawerTitle,
  DrawerDescription,
} from './drawer';
export { ConfirmDialog, type ConfirmDialogProps } from './confirm-dialog';
export {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuLabel,
  DropdownMenuGroup,
} from './dropdown-menu';
export { TooltipProvider, Tooltip, TooltipTrigger, TooltipContent } from './tooltip';
export { Tabs, TabsList, TabsTrigger, TabsContent } from './tabs';
export { Badge, type BadgeProps } from './badge';
export { Alert, type AlertProps } from './alert';
export { Toaster, toast } from './toast';
export { Card, CardHeader, CardTitle, CardBody, CardFooter, type RecordClass } from './card';
export {
  TableContainer,
  Table,
  TableCaption,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
} from './table';
export { Pagination, type PaginationProps } from './pagination';
export { Breadcrumb, type BreadcrumbItem } from './breadcrumb';
export { Skeleton, TableSkeleton } from './skeleton';
export {
  LoadingState,
  EmptyState,
  ErrorState,
  type EmptyKind,
  type EmptyStateProps,
  type ErrorStateProps,
} from './states';
export { VisuallyHidden } from './visually-hidden';
export { DirectionalIcon } from './directional-icon';
